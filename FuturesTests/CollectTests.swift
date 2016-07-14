//
//  CollectTests.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

private let CollectTestsError = NSError(domain: "FutureExtensionsTestsError", code: 1, userInfo: nil)

class CollectTests: XCTestCase {
    
    func testCollect() {
        runWithExpectation("test collect") { exp in
            let f1 = Future.value(1)
            let f2 = Future.value(2)
            
            Futures.collect(futures: [f1, f2]).onSuccess { (values: [Int]) in
                XCTAssertEqual([1, 2], values)
                exp.fulfill()
            }
        }
    }
    
    func testCollect_withOrdering() {
        runWithExpectation("test collect with promise") { exp in
            let f = Future.value(1)
            let p = Promise<Int>()
            
            // make sure p fires after to check ordering
            let futures = [p, f]
            let expected = [2, 1]
            
            Futures.collect(futures: futures).onSuccess { (values: [Int]) in
                XCTAssertEqual(expected, values)
                exp.fulfill()
            }
            
            DispatchQueue.main.async {
                p.succeed(value: 2)
            }
        }
    }
    
    func testCollect_singleFailing() {
        runWithExpectation("test collect single failure") { exp in
            let f = Future.value(1)
            let p = Promise<Int>()
            
            let futures = [p, f]
            
            Futures.collect(futures: futures).onError { _ in
                exp.fulfill()
            }
            
            DispatchQueue.main.async {
                p.fail(error: FutureExtensionsTestsError)
            }
        }
    }
    
    func testCollect_allFailing() {
        runWithExpectation("test collect single failure") { exp in
            let f = Future<Int>.error(FutureExtensionsTestsError)
            let p = Promise<Int>()
            
            let futures = [p, f]
            
            Futures.collect(futures: futures).onError { _ in
                exp.fulfill()
            }
            
            DispatchQueue.main.async {
                p.fail(error: FutureExtensionsTestsError)
            }
        }
    }
    
    func runWithExpectation(_ description: String, execute f: (XCTestExpectation) -> Void) {
        let exp = expectation(withDescription: description)
        f(exp)
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
