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
    
    var parent: Chainable? // need to make this weak
    var child: Chainable?
    
    private var internalState: PromiseState<Element> = .pending
    private var stateQueue = DispatchQueue(label: "com.futures.promise-state-queue", attributes: [.serial], target: nil)
    
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
    
    // MARK: Public method
    
    public func succeed(value: Element) {
        // run side effects...
        // then go down the map chain
    }
    
    public func fail(error: ErrorProtocol) {
        // run side effects...
        // then go down the map chain
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
    
    override func respond(f: (Result<Element>) -> Void) -> Future<Element> {
        // side effects go here
        let p = Promise<Element>()
        return p
    }
    
}

extension Promise: Chainable {
}


