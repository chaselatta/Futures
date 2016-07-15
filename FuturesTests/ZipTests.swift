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
    
    func testZip_succeed() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future.value("foo")).onSuccess { v in
            XCTAssertEqual(v.0, 1)
            XCTAssertEqual(v.1, "foo")
            exp.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    func testZip_failure() {
        let exp = expectation(withDescription: "execute on succeed")
        
        Futures.zip(Future.value(1), Future<String>.error(NSError())).onError { _ in            exp.fulfill()
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
}
