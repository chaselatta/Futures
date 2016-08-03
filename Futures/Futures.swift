//
//  FutureExtensions.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public struct Futures {
    
    public static func void() -> Future<Void> {
        return Future.value(Void())
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
        let count = futures.count
        var results: [T?] = Array(repeating: nil, count: count)
        var firstError: Error? = nil
        
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
            if values.count == count {
                p.succeed(value: values)
            }
        }
        
        return p
    }
    
    /// Picks the first Future that succeeds
    ///
    /// - Parameter futures: An array of Futures to transform
    /// - Returns: A future which will succeed when the first future succeeds
    ///            and will fail with the last error if all of the futures fail
    public static func first<T>(futures: [Future<T>]) -> Future<T> {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "first-queue")
        
        let p = Promise<T>()
        var lastError: Error?
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
    
    /// Collects the futures into a single future which will
    /// signal when completed.
    ///
    /// - Parameter futures: the futures to join
    /// - Returns: a future which is satisfied when all the futures succeed or one fails
    /// - SeeAlso: `collect` if you care about each result
    public static func join<T>(futures: [Future<T>]) -> Future<Void> {
        return collect(futures: futures)
            .map { _ in Void() }
    }
    
    /// Returns a Future which is satisifed when all of the 
    /// futures in the collection succeed. The returned Future
    /// will never fail.
    public static func all<T>(futures: [Future<T>]) -> Future<Void> {
        let p = Promise<Void>()
        
        collect(futures: futures)
            .onSuccess { _ in p.succeed(value: Void()) }
        
        return p
    }
    
    /// Returns a Future which is satisifed when all of the
    /// futures in the collection fail. The returned Future
    /// will never fail.
    public static func none<T>(futures: [Future<T>]) -> Future<Void> {
        let p = Promise<Void>()
        
        let requireFailure = { (f: Future<T>) in
            return f.void().rescue { _ in Futures.void() }
        }
        
        collect(futures: futures.map(requireFailure))
            .onSuccess { _ in p.succeed(value: Void()) }
        
        return p
    }
    
    /// Takes two Futures of different types and returns a Future tuple with the
    /// the results. This method is similar to collect with the exception that it supports
    /// multiple types.
    public static func zip<T, U>(_ f1: Future<T>, _ f2: Future<U>) -> Future<(T, U)> {
        let p = Promise<(T, U)>()
        
        f1.onSuccess{ v1 in
            f2.onSuccess { v2 in
                p.succeed(value: (v1, v2))
            }
        }
        
        collect(futures: [f1.void(), f2.void()])
            .onError(execute: p.fail)
        return p
    }
    
    public static func zip<A, B, C>(_ f1: Future<A>, _ f2: Future<B>, _ f3: Future<C>) -> Future<(A, B, C)> {
        let p = Promise<(A, B, C)>()
        
        f1.onSuccess{ v1 in
            f2.onSuccess { v2 in
                f3.onSuccess { v3 in
                    p.succeed(value: (v1, v2, v3))
                }
            }
        }
        
        collect(futures: [f1.void(), f2.void(), f3.void()])
            .onError(execute: p.fail)
        return p
    }
    
    /// Same thing as calling zip + map
    /// Not yet tested
    private static func combine<A, B, C>(_ f1: Future<A>, _ f2: Future<B>, transform: (A, B) -> C) -> Future<C> {
        return zip(f1, f2).map(transform: transform)
    }
    
    /// Executes a given Future multiple times. This function works by invoking the
    /// next closure and if a Future is returned waits for it to succeed. When it succeeds
    /// the value is passed back into the closure and the process repeats. When no Future
    /// is returned from the next function the Future is satisfied. If any futures fail
    /// the outer future fails as well.
    /// Not yet tested
    private static func repeating<T>(initial: T, next: (T) -> Future<T>?) -> Future<Void> {
        let p = Promise<Void>()

        func inner(_ value: T) {
            if let nextFuture = next(value) {
                nextFuture
                    .onSuccess { inner($0) }
                    .onError(execute: p.fail)
            } else {
                p.succeed(value: Void())
            }
        }
        inner(initial)

        return p
    }
    
}
