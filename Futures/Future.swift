//
//  Future.swift
//  Futures
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public enum Result<T> {
    case satisfied(T)
    case failed(ErrorProtocol)
    
    public var value: T? {
        if case .satisfied(let v) = self {
            return v
        }
        return nil
    }
    
    public var error: ErrorProtocol? {
        if case .failed(let e) = self {
            return e
        }
        return nil
    }
}

public class Future<Element> {
    
    public final class func value(_ value: Element) -> Future<Element> {
        return ConstFuture(result: .satisfied(value))
    }
    
    public final class func error(_ error: ErrorProtocol) -> Future<Element> {
        return ConstFuture(result: .failed(error))
    }
    
    public init() {}
    
    /// poll checks to see if the Future is complete,
    /// returns nil if the value is not fulfilled and 
    /// a Result if it has been fulfilled.
    ///
    /// This is most likely not the method you are looking for
    public func poll() -> Result<Element>? {
        fatalError("poll is an abstract method")
    }
    
    /// cancel will send a signal to the future and up the
    /// chain of futures telling them that they should attempt
    /// to cancel. Calling this method does not guarantee that
    /// the future will be cancelled. The provider of the future
    /// can determine whether the onSuccess/onFailure methods
    /// are invoked based on cancellation
    public func cancel() { /* Intentionally Blank */ }
    
    // MARK: Side effects
    
    @discardableResult
    public func onSuccess(context: InvocationContext? = nil, execute f: (Element) -> Void) -> Future {
        return respond {
            if case .satisfied(let v) = $0 {
                self.with(context: context) { f(v) }
            }
        }
    }
    
    @discardableResult
    public func onError(context: InvocationContext? = nil, execute f: (ErrorProtocol) -> Void) -> Future {
        return respond {
            if case .failed(let e) = $0 {
                self.with(context: context) { f(e) }
            }
        }
    }
    
    private func with(context: InvocationContext?, execute f: () -> Void) {
        if let context = context {
            context.execute(f)
        } else {
            f()
        }
    }
    
    @discardableResult
    internal func respond(_ f: (Result<Element>) -> Void) -> Future {
        fatalError("respond is an abstract method")
    }
    
    // MARK: Transformations
    
    public func map<T>(f: (Element) -> T) -> Future<T> {
        fatalError("map is abstract")
    }
    
    public func flatMap<T>(f: (Element) -> Future<T>) -> Future<T> {
        fatalError("flatMap is abstract")
    }
}

