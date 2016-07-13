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
            withStateQueue {
                switch internalState {
                case .pending:
                    internalState = newValue
                case .fulfilled:
                    fatalError("Attempting to fulfill a promise that has already been fulfilled")
                }
                internalState = newValue
            }
        }
    }
    
    private let sideEffectsQueue = DispatchQueue(label: "com.futures.promise-side-effects-queue", attributes: [.serial], target: nil)
    private var sideEffects = [SideEffect]()
    
    private func withSideEffectsQueue(f: @noescape () -> Void) {
        sideEffectsQueue.sync(execute: f)
    }
    
    private var parentCancelAction = {}
    private var innerCancelAction = {}
    
    // Promise providers can set this value which will be
    // invoked when the promise receives a cancel signal.
    // Note: this variable should be set at the time of 
    // the Promise's creation.
    public var cancelAction: () -> Void = {}
    
    // MARK: Public method
    
    public func succeed(value: Element) {
        let result = Result.satisfied(value)
        fulfill(result)
    }
    
    public func fail(error: ErrorProtocol) {
        let result = Result<Element>.failed(error)
        fulfill(result)
    }
    
    private func fulfill(_ result: Result<Element>) {
        state = .fulfilled(result)
        
        withSideEffectsQueue {
            for f in sideEffects {
                f(result)
            }
        }
    }
    
    // MARK: Overrides
    public override func poll() -> Result<Element>? {
        if case .fulfilled(let r) = state {
            return r
        }
        return nil
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
    
    public override func cancel() {
        parentCancelAction()
        cancelAction()
        innerCancelAction()
    }
    
    public override func map<T>(f: (Element) -> T) -> Future<T> {
        let p: Promise<T> = childPromise()
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
        let p: Promise<T> = childPromise()
        respond { (result) in
            switch result {
            case .satisfied(let v):
                
                let innerPromise = f(v)
                
                innerPromise.respond { (inner) in
                    switch inner {
                    case .satisfied(let innerValue):
                        p.succeed(value: innerValue)
                    case .failed(let innerError):
                        p.fail(error: innerError)
                    }
                }
                
                p.innerCancelAction = { innerPromise.cancel() }
            case .failed(let e):
                p.fail(error: e)
            }
        }
        return p
    }
    
    private func childPromise<T>() -> Promise<T> {
        let p = Promise<T>()
        p.parentCancelAction = { [unowned self] in
            self.cancel()
        }
        return p
    }
    
}
