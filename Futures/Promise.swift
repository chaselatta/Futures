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
    
    // MARK: State Management
    
    /// the backing store for the state of the promise
    /// - Note: do not use this property directly, call state directly
    private var internalState: PromiseState<Element> = .pending
    
    /// the queue used for synchronizing access to the internal state
    private let stateQueue = DispatchQueue(label: "com.futures.promise-state-queue", attributes: [.serial], target: nil)
    
    /// a convenience method for accessing the internalState variable
    private func withStateQueue(f: @noescape () -> Void) {
        stateQueue.sync(execute: f)
    }
    
    /// the current state of the promise, this method is threadsafe
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
    
    // MARK: Side Effects Management
    
    /// the queue which synchronizes access to the side effects
    private let sideEffectsQueue = DispatchQueue(label: "com.futures.promise-side-effects-queue", attributes: [.serial], target: nil)
    
    /// an array of SideEffect functions to execute
    private var sideEffects = [SideEffect]()
    
    /// a convenience mechanism for accessing the side effects
    private func withSideEffectsQueue(f: @noescape () -> Void) {
        sideEffectsQueue.sync(execute: f)
    }
    
    // MARK: Cancellation
    
    /// We use a closure to keep a reference to the parent because
    /// of limitations imposed by swift regarding having stored properties
    /// with differing generics being weak/unowned.
    private var parentCancelAction = {}
    
    /// We use a closure to keep a reference to the proxy because
    /// of limitations imposed by swift regarding having stored properties
    /// with differing generics being weak/unowned.
    private var proxyCancelAction = {}
    
    // Promise providers can set this value which will be
    // invoked when the promise receives a cancel signal.
    // Note: this variable should be set at the time of 
    // the Promise's creation.
    public var cancelAction: () -> Void = {}
    
    // MARK: Initialization
    
    /// the public initializer
    public override init() {}
    
    /// A convenience function for creating a satisfied promise
    public class func succeeded(value: Element) -> Future<Element> {
        let p = Promise<Element>()
        p.internalState = .fulfilled(.satisfied(value))
        return p
    }
    
    /// A convenience function for creating a failed promise
    public class func failed(error: ErrorProtocol) -> Future<Element> {
        let p = Promise<Element>()
        p.internalState = .fulfilled(.failed(error))
        return p
    }
    
    // MARK: Public Methods
    
    /// marks the promise as satisfied
    /// - Parameter value: the value which satisfies the promise
    /// - Note: this method should not be called if the promise is satisfied/failed already
    public func succeed(value: Element) {
        let result = Result.satisfied(value)
        fulfill(result)
    }
    
    /// marks the promise as failed
    /// - Parameter error: the error which fails the promise
    /// - Note: this method should not be called if the promise is satisfied/failed already
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
    override func respond(_ f: (Result<Element>) -> Void) -> Future<Element> {
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
        /// We have to cancel the parent to propogate up the chain
        parentCancelAction()
        
        /// We have to cancel self
        cancelAction()
        
        /// We have to cancel any proxies
        proxyCancelAction()
    }
    
    public override func map<T>(transform: (Element) -> T) -> Future<T> {
        let p: Promise<T> = childPromise()
        respond {  result in
            switch result {
            case .satisfied(let v):
                p.succeed(value: transform(v))
            case .failed(let e):
                p.fail(error: e)
            }
        }
        return p
    }
    
    public override func flatMap<T>(transform: (Element) -> Future<T>) -> Future<T> {
        let outer: Promise<T> = childPromise()
        
        onSuccess {
            outer.proxyVia(promise: transform($0))
        }
        
        onError(execute: outer.fail)
        
        return outer
    }
    
    public override func rescue(transform: (ErrorProtocol) -> Future<Element>) -> Future<Element> {
        let outer: Promise<Element> = childPromise()
        
        onSuccess(execute: outer.succeed)
        
        onError {
            outer.proxyVia(promise: transform($0))
        }

        return outer
    }
    
    private func proxyVia(promise: Future<Element>) {
        promise.onSuccess(execute: succeed)
        promise.onError(execute: fail)
        proxyCancelAction = { promise.cancel() }
    }

    
    public override func by(when: DispatchTime) -> Future<Element> {
        let p: Promise<Element> = childPromise()
        let queue = DispatchQueue(label: "promise-by-queue")
        var fulfilled = false
        
        let doOnce:  (() -> ()) -> () = { f in
            queue.sync {
                if !fulfilled {
                    f()
                    fulfilled = true
                }
            }
        }
        
        Future.after(when: when, value: Void()).onSuccess { _ in
            doOnce { p.fail(error: FutureError.byTimeout) }
        }
        
        onSuccess { v in
            doOnce { p.succeed(value: v) }
        }
        
        onError { e in
            doOnce { p.fail(error: e) }
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
