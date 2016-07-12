//
//  ConstFuturesTests.swift
//  ConstFuturesTests
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

struct ConstFutureTestsError: ErrorProtocol {
    let message: String
}
extension ConstFutureTestsError: Equatable {}
func ==(lhs: ConstFutureTestsError, rhs: ConstFutureTestsError) -> Bool {
    return lhs.message == rhs.message
}

private let Error = ConstFutureTestsError(message: "An error")

class ConstFuturesTests: XCTestCase {

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
        XCTAssertEqual(f.poll()?.error as? ConstFutureTestsError, expected)
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
                if let e = e as? ConstFutureTestsError {
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
    
    func testSuccessCallbackInvoked_MultipleFutures() {
        var called1 = false
        var called2 = false
        
        let f = Future.value(value: 1)
        f.onSuccess { _ in called1 = true }
        f.onSuccess { _ in called2 = true }
        
        XCTAssertTrue(called1)
        XCTAssertTrue(called2)
    }
    
    // MARK: Transformations
    
    func testBasicMap() {
        let f = Future.value(value: "hello world")
        var called = false
        
        f.map { $0.components(separatedBy: " ").count }
            .onSuccess { (count) in
                called = true
                XCTAssert(count == 2)
        }
        
        XCTAssert(called)
    }
    
    func testBasicFlatMap() {
        let f = Future.value(value: "hello world")
        var called = false
        
        f.flatMap { v -> Future<Int> in
            let count = v.components(separatedBy: " ").count
            return Future.value(value: count)
        }.onSuccess { (count) in
            called = true
            XCTAssert(count == 2)
        }
        
        XCTAssert(called)
    }
    
}
