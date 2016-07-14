//
//  FirstsTests.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

class FirstsTests: XCTestCase {
    
    func testFirst_ExecutesFirstSuccess() {
        runWithExpectation("test first executes first success") { exp in
            let p1 = Promise<Int>()
            let p2 = Promise<Int>()
            
            Futures.first(futures: [p1, p2]).onSuccess {
                XCTAssertEqual($0, 2)
                exp.fulfill()
            }
            
            p2.succeed(value: 2)
            p1.succeed(value: 1)
        }
    }
    
    func testFirst_ExecutesLastError() {
        runWithExpectation("test first executes last error") { exp in
            let p1 = Promise<Int>()
            let p2 = Promise<Int>()
            
            let e1 = NSError(domain: "domain", code: 1, userInfo: nil)
            let e2 = NSError(domain: "domain", code: 2, userInfo: nil)
            
            Futures.first(futures: [p1, p2]).onError {
                let error = $0 as NSError
                XCTAssertEqual(error, e2)
                exp.fulfill()
            }
            
            p1.fail(error: e1)
            p2.fail(error: e2)
        }
    }
    
    func testFirst_IgnoreFirstError() {
        runWithExpectation("test first ignores first error") { exp in
            let p1 = Promise<Int>()
            let p2 = Promise<Int>()
            
            let e1 = NSError(domain: "domain", code: 1, userInfo: nil)
            
            Futures.first(futures: [p1, p2]).onSuccess {
                XCTAssertEqual($0, 2)
                exp.fulfill()
            }
            
            p1.fail(error: e1)
            p2.succeed(value: 2)
        }
    }
    
    func runWithExpectation(_ description: String, execute f: (XCTestExpectation) -> Void) {
        let exp = expectation(withDescription: description)
        f(exp)
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
