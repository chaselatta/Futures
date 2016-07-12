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
    
    public class func value(value: Element) -> Future<Element> {
        return ConstFuture(result: .satisfied(value))
    }
    
    public class func error(error: ErrorProtocol) -> Future<Element> {
        return ConstFuture(result: .failed(error))
    }
    
    /// poll checks to see if the Future is complete,
    /// returns nil if the value is not fulfilled and 
    /// a Result if it has been fulfilled.
    ///
    /// This is most likely not the method you are looking for
    public func poll() -> Result<Element>? {
        fatalError("poll is an abstract method")
    }
    
    // MARK: Side effects
    
    @discardableResult
    public func onSuccess(f: (Element) -> Void) -> Future {
        fatalError("onSuccess is an abstract method")
    }
    
    @discardableResult
    public func onError(f: (ErrorProtocol) -> ()) -> Future {
        fatalError("onError is an abstract method")
    }
    
    @discardableResult
    public func respond(f: (Result<Element>) -> Void) -> Future {
        fatalError("respond is an abstract method")
    }
}

