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
    
    func testMultipleSideEffects() {
        let p = Promise<Bool>()
        var count = 0
        
        let incr: (Bool) -> Void = { _ in count += 1 }
        p.onSuccess(f: incr)
        p.onSuccess(f: incr)
        
        p.succeed(value: true)
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
    
    // MARK: transformation tests
    func testBasicFlatMap() {
        let p = Promise<String>()
        var called = false
        
        p.flatMap { v -> Future<Int> in
            let count = v.components(separatedBy: " ").count
            return Future.value(value: count)
            }.onSuccess { (count) in
                called = true
                XCTAssert(count == 2)
        }
        
        p.succeed(value: "Hello world")
        XCTAssert(called)
    }
    
    func testCrazyMap() {
        let p = Promise<Int>()
        var called = false
        p
            .map { String($0) }
            .map { Int($0)! + 1 }
            .flatMap { Future.value(value: String($0)) }
            .map { Int($0)! + 1 }
            .onSuccess { v in
                called = true
                XCTAssertEqual(v, 2)
        }
        p.succeed(value: 0)
        XCTAssert(called)
    }
    
    func testMap_WithFail() {
        let p = Promise<Int>()
        var called = false
        
        let _ = p.map { v -> Int in
            called = true
            return v
        }
        
        p.fail(error: PromiseError)
        XCTAssertFalse(called)
    }
    
    func testFlatMap_WithFail() {
        let p = Promise<Int>()
        var called = false
        
        let _ = p.flatMap { v -> Future<Int> in
            called = true
            return Future.value(value: v)
        }
        
        p.fail(error: PromiseError)
        XCTAssertFalse(called)
    }
    
    // MARK: async tests
    func testRespondNotCalledImmediately() {
        let syncP = Promise<Int>()
        let asyncP = Promise<Int>()
        
        var calledSync = false
        var calledAsync = false
        
        syncP.respond { _ in calledSync = true }
        asyncP.respond { _ in calledAsync = true }
        
        DispatchQueue.main.async { 
            asyncP.succeed(value: 1)
        }
        
        syncP.succeed(value: 1)
        
        XCTAssertTrue(calledSync)
        XCTAssertFalse(calledAsync)
    }
    
    func testAsync_noMap() {
        let p = Promise<Int>()

        let exp = self.expectation(withDescription: "wait for promise")
        p.respond { _ in exp.fulfill() }
        
        let time = DispatchTime.now() + .milliseconds(20)
        DispatchQueue.main.after(when: time) {
            p.succeed(value: 1)
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testAsync_withMap() {
        let p = Promise<Int>()
        
        let exp = self.expectation(withDescription: "wait for promise")
        p.map { String($0) }.respond { _ in exp.fulfill() }
        
        let time = DispatchTime.now() + .milliseconds(20)
        DispatchQueue.main.after(when: time) {
            p.succeed(value: 1)
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testAsync_withFlatMap() {
        let p = Promise<Int>()
        
        let exp = self.expectation(withDescription: "wait for promise")
        p.flatMap { Future.value(value: String($0)) }.respond { _ in exp.fulfill() }
        
        let time = DispatchTime.now() + .milliseconds(20)
        DispatchQueue.main.after(when: time) {
            p.succeed(value: 1)
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testFlatmapWithAPromise() {
        let p = Promise<Int>()
        
        let exp = self.expectation(withDescription: "wait for promise")
        p.flatMap { _ -> Future<Int> in
            let innerP = Promise<Int>()
            let time = DispatchTime.now() + .milliseconds(10)
            DispatchQueue.main.after(when: time) {
                innerP.succeed(value: 2)
            }
            return innerP
        }.respond { v in
            exp.fulfill()
        }
        
        let time = DispatchTime.now() + .milliseconds(10)
        DispatchQueue.main.after(when: time) {
            p.succeed(value: 1)
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    // MARK: Cancellation
    
    func testCancelInvokesCancelAction() {
        let p = Promise<Any>()
        var cancelled = false
        p.cancelAction = { cancelled = true }
        
        p.cancel()
        XCTAssertTrue(cancelled)
    }
    
    func testCancelInvokesCancelAction_mapped() {
        let parent = Promise<Any>()
        let child = parent.map { _ in "foo" }
        
        var cancelled = false
        
        parent.cancelAction = { cancelled = true }
        
        child.cancel()
        XCTAssertTrue(cancelled)
    }
    
    func testCancelInvokesCancelAction_flatMapped() {
        let parent = Promise<Any>()
        let child = parent.flatMap { _ in Future.value(value: 1) }
        
        var cancelled = false
        
        parent.cancelAction = { cancelled = true }
        
        child.cancel()
        XCTAssertTrue(cancelled)
    }
    
    func testCancelInvokesCancelAction_flatMappedPromise() {
        let parent = Promise<Int>()
        var cancelled = false

        let child = parent.flatMap { v -> Future<Int> in
            let p = Promise<Int>()
            p.cancelAction = { cancelled = true }
            return p
        }
        
        // need this to succeed so the flatMap gets invoked
        parent.succeed(value: 1)
        child.cancel()
        XCTAssertTrue(cancelled)
    }
    
}
