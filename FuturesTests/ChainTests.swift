//
//  ChainTests.swift
//  Futures
//
//  Created by Chase Latta on 7/11/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import XCTest
@testable import Futures

class Link: Chainable {
    
    private let value: Any
    internal var parent: Chainable?
    internal var child: Chainable?
    
    init(_ value: Any) {
        self.value = value
    }
    
    func valueAs<T>() -> T? {
        return value as? T
    }
}


class ChainTests: XCTestCase {
    
    func testGetValue() {
        let link = Link(1)
        XCTAssertEqual(link.valueAs(), 1)
    }
    
    func testGetValueWrongType() {
        let link = Link(1)
        let value: String? = link.valueAs()
        XCTAssertNil(value)
    }
    
    func testChain_TopValue() {
        let expected = "expected_value"
        let parent = Link(expected)
        let child = Link(1)
        
        Chain.append(child: child, toParent: parent)
        
        var value: String?
        Chain.withTop(link: child) { value = ($0 as? Link)?.valueAs() }
        XCTAssertEqual(value, expected)
    }
    
    func testChain_BottomValue() {
        let expected = 1
        let parent = Link("value")
        let child = Link(expected)
        
        Chain.append(child: child, toParent: parent)
        
        var value: Int?
        Chain.withBottom(link: parent) { value = ($0 as? Link)?.valueAs() }
        XCTAssertEqual(value, expected)
    }
    
}
