//
//  FuturesTests.swift
//  FuturesTests
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

struct FutureTestsError: ErrorProtocol {
    let message: String
}
extension FutureTestsError: Equatable {}
func ==(lhs: FutureTestsError, rhs: FutureTestsError) -> Bool {
    return lhs.message == rhs.message
}

private let Error = FutureTestsError(message: "An error")

class FuturesTests: XCTestCase {

    func testConstFuturePoll_Value() {
        let expected = "expected"
        let f = Future.value(value: expected)
        XCTAssertEqual(f.poll()?.value, expected)
    }
    
    func testConstFuturePollEmptyError_Value() {
        let expected = "expected"
        let f = Future.value(value: expected)
        XCTAssertNil(f.poll()?.error)
    }
    
    func testConstFuturePoll_Error() {
        let expected = Error
        let f = Future<Any>.error(error: expected)
        XCTAssertEqual(f.poll()?.error as? FutureTestsError, expected)
    }
    
    func testConstFuturePollEmptyValue_Error() {
        let f = Future<Any>.error(error: Error)
        XCTAssertNil(f.poll()?.value)
    }
    
    func testSuccessBlockInvoked_ValueFuture() {
        let expected = 1
        let f = Future.value(value: expected)
        var value = expected - 1
        
        f.onSuccess { v in value = v }

        XCTAssertTrue(value == expected)
    }

    func testSuccessBlockNotInvoked_ErrorFuture() {
        var called = false
        Future<Any>.error(error: Error)
            .onSuccess { _ in called = true }
        
        XCTAssertFalse(called)
    }

    func testFailureBlockInvoked_ErrorFuture() {
        let expected = Error
        var called = false
        
        Future<Any>.error(error: Error).onError { e in
                if let e = e as? FutureTestsError {
                    XCTAssertTrue(e == expected)
                }
                
                called = true
        }
        
        XCTAssertTrue(called)
    }

    func testFailureNotBlockInvoked_ValueFuture() {
        var called = false
        Future.value(value: 1).onError { _ in called = true }
        
        XCTAssertFalse(called)
    }
    
}
