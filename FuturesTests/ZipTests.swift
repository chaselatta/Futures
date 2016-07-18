//
//  ZipTests.swift
//  Futures
//
//  Created by Chase Latta on 7/14/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

struct ZipError: ErrorProtocol {}

class ZipTests: XCTestCase {
    
    func testZip_succeedFirst() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future.value("foo"))
            .onSuccess { v in
                XCTAssertEqual(v.0, 1)
                XCTAssertEqual(v.1, "foo")
                exp.fulfill()
            }.onError { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_succeedLast() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value("foo"), Future.value(1))
            .onSuccess { v in
                XCTAssertEqual(v.1, 1)
                XCTAssertEqual(v.0, "foo")
                exp.fulfill()
            }.onError { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_failureLast() {
        let exp = expectation(withDescription: "execute on error")
        
        Futures.zip(Future.value(1), Future<String>.error(ZipError()))
            .onError { _ in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_failureFirst() {
        let exp = expectation(withDescription: "execute on error")
        
        Futures.zip(Future<String>.error(ZipError()), Future.value(1))
            .onError { _ in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_bothFail() {
        let e1 = NSError(domain: "domain", code: 1, userInfo: nil)
        let e2 = NSError(domain: "domain", code: 2, userInfo: nil)
        let exp = expectation(withDescription: "execute on error")
        
        Futures.zip(Future<String>.error(e1), Future<Int>.error(e2))
            .onError { e in
                XCTAssertEqual(e as NSError, e1)
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_delayedFirstFail() {
        let p = Promise<String>()
        let exp = expectation(withDescription: "execute on error")
        
        Futures.zip(p, Future.value(1))
            .onError { e in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        DispatchQueue.main.async {
            p.fail(error: ZipError())
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_delayedSecondFail() {
        let p = Promise<String>()
        let exp = expectation(withDescription: "execute on error")
        
        Futures.zip(Future.value(1), p)
            .onError { e in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        DispatchQueue.main.async {
            p.fail(error: ZipError())
        }
    
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_delayedBothFailSecondFirst() {
        let e1 = NSError(domain: "domain", code: 1, userInfo: nil)
        let e2 = NSError(domain: "domain", code: 2, userInfo: nil)
        let exp = expectation(withDescription: "execute on error")
        
        let p1 = Promise<Any>()
        let p2 = Promise<Any>()

        Futures.zip(p1, p2)
            .onError { e in
                XCTAssertEqual(e as NSError, e2)
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        DispatchQueue.main.async {
            p2.fail(error: e2)
            DispatchQueue.main.async {
                p1.fail(error: e1)
            }
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
