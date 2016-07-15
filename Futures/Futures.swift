//
//  FutureExtensions.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

// Need better error code and domain
public let FuturesOptionalFailureError = NSError(domain: "com.futures.futures", code: 1, userInfo: nil)

public struct Futures {
    
    public static func optional<T>(_ value: T?, error: ErrorProtocol = FuturesOptionalFailureError) -> Future<T> {
        if let v = value {
            return .value(v)
        } else {
            // need some error
            return .error(error)
        }
    }
    
    public static func throwable<T>(throwable f: () throws -> T) -> Future<T> {
        do {
            return .value(try f())
        } catch {
            return .error(error)
        }
    }
    
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
                    switch result {
                    case .satisfied(let v):
                        results[idx] = v
                    case .failed(let e):
                        if firstError == nil {
                            firstError = e
                            p.fail(error: e)
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
        // This is a really ugly implementation and I would like to clean it up but I just wanted something that works
        let p = Promise<(T, U)>()
        var first: T?
        var second: U?
        var failed = false
        let context = InvocationContext.sync(on: DispatchQueue(label: "zip-queue"))
        
        let succeedMaybe = {
            if let first = first, second = second {
                p.succeed(value: (first, second))
            }
        }
        
        f1.onSuccess(context: context) { v in
            first = v
            succeedMaybe()
        }
        
        f2.onSuccess(context: context) { v in
            second = v
            succeedMaybe()
        }
        
        f1.onError(context: context) { e in
            if !failed {
                p.fail(error: e)
                failed = true
            }
        }
        
        f2.onError(context: context) { e in
            if !failed {
                p.fail(error: e)
                failed = true
            }
        }
        
        return p
    }
    
}
