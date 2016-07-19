//
//  AwaitTests.swift
//  Futures
//
//  Created by Chase Latta on 7/18/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
import Futures

class AwaitTests: XCTestCase {
    
    func testAwaitResult() {
        let f = Future.value(1)
        do {
            let v = try Await.result(future: f)
            XCTAssertEqual(v, 1)
        } catch {
            XCTFail()
        }
    }
    
    
    func testAwaitResult_delayed() {
        let f = Promise.after(when: .now() + .milliseconds(10), value: 1)
        let exp = expectation(withDescription: "wait for promise")
        do {
            let v = try Await.result(future: f)
            XCTAssertEqual(v, 1)
            exp.fulfill()
        } catch {
            XCTFail()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func testAwaitFail() {
        let e = NSError(domain: "await", code: 1, userInfo: nil)
        let f = Future<Any>.error(e)
        do {
            let _ = try Await.result(future: f)
            XCTFail("should throw")
        } catch {
            XCTAssertEqual(e, error as NSError)
        }
    }
    
    
    func testAwaitFail_delayed() {
        let e = NSError(domain: "await", code: 1, userInfo: nil)
        let f = Promise<Any>()
        
        DispatchQueue.global().async {
            f.fail(error: e)
        }
        do {
            let _ = try Await.result(future: f)
            XCTFail("should throw")
        } catch {
            XCTAssertEqual(e, error as NSError)
        }
    }
    
}
