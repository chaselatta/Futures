//
//  FutureExtensions.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public struct Futures {
    
    /// Transforms the given array of Futures to a single Future
    /// of all the results.
    ///
    /// - Parameter futures: An array of Futures to transform
    /// - Returns: A future which will succeed if all Futures succeed and 
    ///            will fail if any of the futures fail
    public static func collect<T>(futures: [Future<T>]) -> Future<[T]> {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "collect-queue")
        
        let p = Promise<[T]>()
        var results: [T?] = Array(repeating: nil, count: futures.count)
        var firstError: ErrorProtocol? = nil
        
        for (idx, f) in futures.enumerated() {
            group.enter()
            f.respond { result in
                queue.sync {
                    result.withValue { results[idx] = $0 }
                    result.withError { error in
                        if firstError == nil {
                            firstError = error
                            p.fail(error: error)
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            let values = results.flatMap { $0 }
            if values.count == futures.count {
                p.succeed(value: values)
            }
        }
        
        return p
    }
    
    /// Picks the first Future that succeeds
    ///
    /// - Parameter futures: An array of Futures to transform
    /// - Returns: A future which will succeed when the first future succeeds
    ///            and will fail if all of the futures fail
    public static func first<T>(futures: [Future<T>]) -> Future<T> {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "first-queue")
        
        let p = Promise<T>()
        var lastError: ErrorProtocol?
        var succeeded = false
        
        for f in futures {
            group.enter()
            f.respond { result in
                queue.sync {
                    if succeeded {
                        return
                    }
                    
                    switch result {
                    case .satisfied(let v):
                        p.succeed(value: v)
                        succeeded = true
                        lastError = nil
                    case .failed(let e):
                        lastError = e
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            if let error = lastError {
                p.fail(error: error)
            }
        }
        
        return p
    }
    
    /// Takes two Futures of different types and returns a Future tuple with the
    /// the results. This method is similar to collect with the exception that it supports
    /// multiple types.
    public static func zip<T, U>(_ f1: Future<T>, _ f2: Future<U>) -> Future<(T, U)> {
        let p = Promise<(T, U)>()
        
        let failOnce = { (e: ErrorProtocol) in
            if p.poll() == nil {
                p.fail(error: e)
            }
        }
        
        f1.onSuccess{ v1 in
            f2.onSuccess { v2 in
                p.succeed(value: (v1, v2))
            }
        }
        f1.onError(execute: failOnce)
        f2.onError(execute: failOnce)
        return p
    }    
}

private extension Optional {
    
    func takeIfNone(value: Wrapped?) -> Optional<Wrapped> {
        switch self {
        case .some:
            return self
        case .none:
            return value
        }
    }
}
