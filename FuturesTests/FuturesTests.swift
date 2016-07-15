//
//  FuturesTests.swift
//  Futures
//
//  Created by Chase Latta on 7/14/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

class FuturesTests: XCTestCase {
    
    func testOptionalFailure() {
        let v: Int? = nil
        let f = Futures.optional(v)
        
        let exp = expectation(withDescription: "execute on error")
        f.onError { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testOptionalFailureWithError() {
        let v: Int? = nil
        let error = NSError(domain: "my-domain", code: 123, userInfo: nil)

        let f = Futures.optional(v, error: error)
        let exp = expectation(withDescription: "execute on error")
        
        f.onError { e in
            XCTAssertEqual(e as NSError, error)
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testOptionalSucceed() {
        let expected: Int? = 1
        
        let f = Futures.optional(expected)
        let exp = expectation(withDescription: "execute on success")
        
        f.onSuccess { value in
            XCTAssertEqual(value, expected)
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func thrower(error: NSError?, value: Int = 0) throws -> Int {
        if let error = error {
            throw error
        }
        return value
    }
    
    func testThrowableFail() {
        let error = NSError(domain: "my-domain", code: 123, userInfo: nil)
 
        let f = Futures.throwable { try self.thrower(error: error) }
        
        let exp = expectation(withDescription: "execute on error")
        
        f.onError { e in
            XCTAssertEqual(e as NSError, error)
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testThrowableSucceed_Void() {
        let f = Futures.throwable { }
        
        let exp = expectation(withDescription: "execute on error")
        
        f.onSuccess { _ in
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testThrowableSucceed_Value() {
        let expected = 1
        let f = Futures.throwable { try self.thrower(error: nil, value: expected) }
        
        let exp = expectation(withDescription: "execute on succeed")
        
        f.onSuccess { v in
            XCTAssertEqual(v, expected)
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_succeed() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future.value("foo")).onSuccess { v in
            XCTAssertEqual(v.0, 1)
            XCTAssertEqual(v.1, "foo")
            exp.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_failure() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future<String>.error(NSError())).onError { _ in            exp.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
