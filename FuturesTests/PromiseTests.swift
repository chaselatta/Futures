//
//  PromiseTests.swift
//  Futures
//
//  Created by Chase Latta on 7/11/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

private let PromiseError = NSError(domain: "com.futures.promise-tests", code: -1, userInfo: nil)

private extension Result {
    var promiseError: NSError? {
        return error as? NSError
    }
}

class PromiseTests: XCTestCase {
    
    func testPoll_EmptyReturnsNil() {
        let p = Promise<Any>()
        XCTAssertNil(p.poll())
    }
    
    func testPoll_EmptyReturnsNilChained() {
        let p = Promise<Any>()
        let child = p.map { $0 }
        XCTAssertNil(child.poll())
    }
    
    func testPoll_SucceedReturnsValue() {
        let p = Promise<Int>()
        p.succeed(value: 1)
        XCTAssertEqual(p.poll()?.value, 1)
    }
    
    func testPoll_SucceedReturnsValueChained() {
        let p = Promise<Int>()
        // should map to something else to test that
        let child = p.map { $0 }
        p.succeed(value: 1)
        XCTAssertEqual(child.poll()?.value, 1)
    }
    
    func testPoll_FailReturnsError() {
        let p = Promise<Int>()
        p.fail(error: PromiseError)
        XCTAssertEqual(p.poll()?.promiseError, PromiseError)
    }
    
    func testPoll_FailReturnsErrorChained() {
        let p = Promise<Int>()
        let child = p.map { $0 }
        p.fail(error: PromiseError)
        XCTAssertEqual(child.poll()?.promiseError, PromiseError)
    }
    
    // MARK: Completion 
    func testSucceedCalled_BeforeSucceed() {
        let expected = 1
        var succesValue = 0
        let p = Promise<Int>()
        
        p.onSuccess { succesValue = $0 }
        p.succeed(value: expected)

        XCTAssertEqual(succesValue, expected)
    }
    
    func testSucceedCalled_AfterSucceed() {
        let expected = 1
        var succesValue = 0
        
        let p = Promise<Int>()
        p.succeed(value: expected)
        
        p.onSuccess { succesValue = $0 }
        XCTAssertEqual(succesValue, expected)
    }
    
    func testFailedCalled_BeforeFail() {
        var called = false
        let p = Promise<Int>()
        
        p.onError { _ in called = true }
        p.fail(error: PromiseError)
        
        XCTAssertTrue(called)
    }
    
    func testFailedCalled_AfterFail() {
        var called = false
        let p = Promise<Int>()
        p.fail(error: PromiseError)
        
        p.onError { _ in called = true }
        XCTAssertTrue(called)
    }
    
    // MARK: Transformations
    
    func testBasicMap() {
        let p = Promise<String>()
        var called = false
        
        p.map { $0.components(separatedBy: " ").count }
            .onSuccess { (count) in
                called = true
                XCTAssert(count == 2)
        }
        
        p.succeed(value: "hello world")
        XCTAssert(called)
    }
    
//    func testBasicFlatMap() {
//        let f = Future.value(value: "hello world")
//        var called = false
//        
//        f.flatMap { v -> Future<Int> in
//            let count = v.components(separatedBy: " ").count
//            return Future.value(value: count)
//            }.onSuccess { (count) in
//                called = true
//                XCTAssert(count == 2)
//        }
//        
//        XCTAssert(called)
//    }
    
}
