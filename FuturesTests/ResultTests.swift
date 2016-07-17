//
//  ResultTests.swift
//  Futures
//
//  Created by Chase Latta on 7/17/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
import Futures

class ResultTests: XCTestCase {
    
    private let error = NSError(domain: "results-test", code: 123, userInfo: nil)
    
    func testWithValue() {
        let r = Result.satisfied("foo")
        r.withValue { XCTAssertEqual($0, "foo") }
    }
    
    func testWithError() {
        let r = Result<Any>.failed(error)
        r.withError { XCTAssertEqual($0 as NSError, self.error) }
    }
    
    func testChainingSatisfied() {
        Result.satisfied(1)
            .withError { _ in XCTFail("Should not call this method") }
            .withValue { XCTAssertEqual($0, 1) }
    }
    
    func testChainingFailed() {
        Result<Any>.failed(error)
            .withValue { _ in XCTFail("Should not call this method") }
            .withError { XCTAssertEqual($0 as NSError, self.error) }
    }
    
    func testValue() {
        XCTAssertEqual(Result.satisfied(1).value, 1)
    }
    
    func testValue_fail() {
        XCTAssertNil(Result<Any>.failed(error).value)
    }
    
    func testError() {
        XCTAssertEqual(Result<Any>.failed(error).error as? NSError, error)
    }
    
    func testError_satisfied() {
        XCTAssertNil(Result.satisfied(1).error)
    }

}
