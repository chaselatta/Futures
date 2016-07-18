//
//  ZipTests.swift
//  Futures
//
//  Created by Chase Latta on 7/14/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

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
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future<String>.error(NSError()))
            .onError { _ in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_failureFirst() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future<String>.error(NSError()), Future.value(1))
            .onError { _ in
                exp.fulfill()
            }.onSuccess { _ in XCTFail() }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
