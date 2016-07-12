//
//  ConstFuture.swift
//  Futures
//
//  Created by Chase Latta on 7/11/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

internal class ConstFuture<Element>: Future<Element> {
    
    private let result: Result<Element>
    
    init(result: Result<Element>) {
        self.result = result
    }
    
    override func poll() -> Result<Element>? {
        return result
    }
    
    override func respond(f: (Result<Element>) -> Void) -> Future<Element> {
        f(result)
        return self
    }
    
    
    override func map<T>(f: (Element) -> T) -> Future<T> {
        switch result {
        case .satisfied(let v):
            return Future<T>.value(value: f(v))
        case .failed(let e):
            return Future<T>.error(error: e)
        }
    }
    
    override func flatMap<T>(f: (Element) -> Future<T>) -> Future<T> {
        switch result {
        case .satisfied(let v):
            return f(v)
        case .failed(let e):
            return Future<T>.error(error: e)
        }
    }
}
