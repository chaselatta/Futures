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
    case failed(Error)
    
    public func withValue(execute: (T) -> Void) {
        if case .satisfied(let v) = self {
            execute(v)
        }
    }
    
    public func withError(execute: (Error) -> Void) {
        if case .failed(let e) = self {
            execute(e)
        }
    }
    
    public var value: T? {
        var value: T? = nil
        withValue { value = $0 }
        return value
    }
    
    public var error: Error? {
        var error: Error? = nil
        withError { error = $0 }
        return error
    }
}
