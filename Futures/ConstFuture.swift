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
    
    override func onSuccess(f: (Element) -> Void) -> Future<Element> {
        return respond {
            if case .satisfied(let v) = $0 {
                f(v)
            }
        }
    }
    
    override func onError(f: (ErrorProtocol) -> ()) -> Future<Element> {
        return respond {
            if case .failed(let e) = $0 {
                f(e)
            }
        }
    }
    
    override func respond(f: (Result<Element>) -> Void) -> Future<Element> {
        f(result)
        return self
    }
}
