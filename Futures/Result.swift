//
//  Result.swift
//  Futures
//
//  Created by Chase Latta on 7/17/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public enum Result<T> {
    case satisfied(T)
    case failed(ErrorProtocol)
    
    @discardableResult
    public func withValue(execute: (T) -> Void) -> Result<T> {
        if case .satisfied(let v) = self {
            execute(v)
        }
        return self
    }
    
    @discardableResult
    public func withError(execute: (ErrorProtocol) -> Void) -> Result<T> {
        if case .failed(let e) = self {
            execute(e)
        }
        return self
    }
    
    public var value: T? {
        var value: T? = nil
        withValue { value = $0 }
        return value
    }
    
    public var error: ErrorProtocol? {
        var error: ErrorProtocol? = nil
        withError { error = $0 }
        return error
    }
}
