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
    private var proxyCancelAction = {}
    
    // Promise providers can set this value which will be
    // invoked when the promise receives a cancel signal.
    // Note: this variable should be set at the time of 
        // the Promise's creation.
    public var cancelAction: () -> Void = {}
    
    // MARK: Public method
    
    public override init() {}
    
    public class func succeeded(value: Element) -> Future<Element> {
        let p = Promise<Element>()
        p.internalState = .fulfilled(.satisfied(value))
        return p
    }
    
    public class func failed(error: ErrorProtocol) -> Future<Element> {
        let p = Promise<Element>()
        p.internalState = .fulfilled(.failed(error))
        return p
    }
    
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
        /// There is probably a better way to make this work but it works for now
        
        /// We have to cancel the parent to propogate up the chain
        parentCancelAction()
        
        /// We have to cancel self
        cancelAction()
        
        /// We have to cancel any proxies
        proxyCancelAction()
    }
    
    public override func map<T>(f: (Element) -> T) -> Future<T> {
        let p: Promise<T> = childPromise()
        respond {  result in
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
        let outer: Promise<T> = childPromise()
        
        onSuccess {
            outer.proxyVia(promise: f($0))
        }
        
        onError(execute: outer.fail)
        
        return outer
    }
    
    public override func rescue(f: (ErrorProtocol) -> Future<Element>) -> Future<Element> {
        let outer: Promise<Element> = childPromise()
        
        onSuccess(execute: outer.succeed)
        
        onError {
            outer.proxyVia(promise: f($0))
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
