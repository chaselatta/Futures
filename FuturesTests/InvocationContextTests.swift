//
//  InvocationContextTests.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

class InvocationContextTests: XCTestCase {
    
    var future: Future<Int>!
    var failedFuture: Future<Any>!
    var queue: DispatchQueue!
    let key = DispatchSpecificKey<String>()
    
    override func setUp() {
        super.setUp()
        future = Future.value(1)
        failedFuture = Future.error(NSError(domain: "", code: 1, userInfo: nil))
        
        queue = DispatchQueue(label: "invocation-tests-queue")
        queue.setSpecific(key: key, value: "InvocationContextTests")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    var isCorrectQueue: Bool {
        let v = DispatchQueue.getSpecific(key: key)
        return v == "InvocationContextTests"
    }
    
    func testFutureInvokedNil_sync_currentQueue() {
        let exp = expectation(withDescription: "wait for invocation")
        future.onSuccess {_ in 
            exp.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testPromiseInvokedNil_sync_currentQueue() {
        let p = Promise<Int>()
        let exp = expectation(withDescription: "wait for invocation")
        future.onSuccess {_ in
            exp.fulfill()
        }
        p.succeed(value: 1)
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testFutureInvokedOnQueue_sync() {
        var correctQ = false
        future.onSuccess(context: .sync(on: queue)) { _ in
            correctQ = self.isCorrectQueue
        }
        XCTAssertTrue(correctQ)
    }
    
    func testFutureInvokedOnQueue_async() {
        var correctQ = false
        let exp = expectation(withDescription: "wait for async")
        future.onSuccess(context: .async(on: queue)) { _ in
            correctQ = self.isCorrectQueue
            exp.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(correctQ)
    }
    
    func testPromiseInvokedOnQueue_sync() {
        let p = Promise<Int>()
        var correctQ = false
        p.onSuccess(context: .sync(on: queue)) { _ in
            correctQ = self.isCorrectQueue
        }
        p.succeed(value: 1)
        XCTAssertTrue(correctQ)
    }
    
    func testPromiseInvokedOnQueue_async() {
        let p = Promise<Int>()
        var correctQ = false
        let exp = expectation(withDescription: "wait for async")
        p.onSuccess(context: .async(on: queue)) { _ in
            correctQ = self.isCorrectQueue
            exp.fulfill()
        }
        
        // will fail because async
        p.succeed(value: 1)
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(correctQ)
    }
}
