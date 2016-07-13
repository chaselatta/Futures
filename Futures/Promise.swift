//
//  Promise.swift
//  Futures
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

private enum PromiseState<T> {
    case pending
    case fulfilled(Result<T>)
}

public class Promise<Element>: Future<Element> {
    
    private typealias SideEffect = (Result<Element>) -> Void
    
    var parent: Chainable? // need to make this weak
    var child: Chainable?
    
    private var internalState: PromiseState<Element> = .pending
    private let stateQueue = DispatchQueue(label: "com.futures.promise-state-queue", attributes: [.serial], target: nil)
    
    private func withStateQueue(f: @noescape () -> Void) {
        stateQueue.sync(execute: f)
    }
    
    private var state: PromiseState<Element> {
        get {
            var s: PromiseState<Element> = .pending
            withStateQueue { s = internalState }
            return s
        }
        set {
            withStateQueue { internalState = newValue }
        }
    }
    
    private let sideEffectsQueue = DispatchQueue(label: "com.futures.promise-side-effects-queue", attributes: [.serial], target: nil)
    private var sideEffects = [SideEffect]()
    
    private func withSideEffectsQueue(f: @noescape () -> Void) {
        sideEffectsQueue.sync(execute: f)
    }
    
    // MARK: Public method
    
    public func succeed(value: Element) {
        //TODO: Check if we are already fulfilled
        let result = Result.satisfied(value)
        state = .fulfilled(result)
        
        withSideEffectsQueue {
            for f in sideEffects {
                f(result)
            }
        }
    }
    
    public func fail(error: ErrorProtocol) {
        //TODO: Check if we are already fulfilled
        //TODO: deduplicate code
        let result = Result<Element>.failed(error)
        state = .fulfilled(result)
        
        withSideEffectsQueue {
            for f in sideEffects {
                f(result)
            }
        }
    }
    
    // MARK: Overrides
    public override func poll() -> Result<Element>? {
        var result: Result<Element>? = nil
        Chain.withTop(link: self) { (v) in
            guard let v = v as? Promise else {
                fatalError("Uknown type in chain")
            }
            if case .fulfilled(let r) = v.state {
                result = r
            }
        }
        return result
    }
    
    @discardableResult
    override func respond(f: (Result<Element>) -> Void) -> Future<Element> {
        withSideEffectsQueue {
            if let result = self.poll() {
                f(result)
            } else {
                sideEffects.append(f)
            }
        }
        return self
    }
    
    public override func map<T>(f: (Element) -> T) -> Future<T> {
        let p = Promise<T>()
        respond { (result) in
            switch result {
            case .satisfied(let v):
                p.succeed(value: f(v))
            case .failed(let e):
                p.fail(error: e)
            }
        }
        return p
    }
    
    public override func flatMap<T>(f: (Element) -> Future<T>) -> Future<T> {
        let p = Promise<T>()
        respond { (result) in
            switch result {
            case .satisfied(let v):
                f(v).respond { (inner) in
                    switch inner {
                    case .satisfied(let innerV):
                        p.succeed(value: innerV)
                    case .failed(let innerE):
                        p.fail(error: innerE)
                    }
                }
            case .failed(let e):
                p.fail(error: e)
            }
        }
        return p
    }
    
}

extension Promise: Chainable {
}


