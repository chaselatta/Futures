//
//  FuturesTests.swift
//  Futures
//
//  Created by Chase Latta on 7/19/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
import Futures

private struct FuturesError: ErrorProtocol {}

class FuturesTests: XCTestCase {
    
    func testJoin_Succeed() {
        let exp = expectation(withDescription: "wait for success")
        Futures.join(futures: [.value(1), .value(2)])
            .onSuccess { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testJoin_Fail() {
        let exp = expectation(withDescription: "wait for failure")
        Futures.join(futures: [.error(FuturesError()), .value(2)])
            .onError { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testAll_Succeed() {
        let exp = expectation(withDescription: "wait for success")
        Futures.all(futures: [.value(1), .value(2)])
            .onSuccess { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testAll_WithFailNeverSucceeds() {
        let exp = expectation(withDescription: "wait for failure from timeout")
        Futures.all(futures: [.error(FuturesError()), .value(2)])
            .by(when: .now() + .milliseconds(2))
            .onError { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testNone_Fail() {
        let exp = expectation(withDescription: "wait for success")
        Futures.none(futures: [Future<Any>.error(FuturesError()), Future<Any>.error(FuturesError())])
            .onSuccess { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testNone_WithSucceedNeverSucceeds() {
        let exp = expectation(withDescription: "wait for failure from timeout")
        Futures.none(futures: [Future<Any>.error(FuturesError()), Future<Any>.value(2)])
            .by(when: .now() + .milliseconds(2))
            .onSuccess { _ in exp.fulfill() }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
