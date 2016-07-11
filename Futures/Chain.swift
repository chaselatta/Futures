//
//  Chain.swift
//  Futures
//
//  Created by Chase Latta on 7/11/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

protocol Chainable {
    
    var parent: Chainable? { get set }
    var child: Chainable? { get set }

}

struct Chain {
    
    private static let accessQueue = DispatchQueue(label: "com.futures.chain-access-queue", attributes: [.serial], target: nil)
    
    private static func withQueue(f: () -> Void) {
        accessQueue.sync(execute: f)
    }
    
    static func append(child: Chainable, toParent parent: Chainable) {
        var child = child
        withQueue { 
            var deepestLink: Chainable = parent
            while let nextLink = deepestLink.child {
                deepestLink = nextLink
            }
        
            deepestLink.child = child
            child.parent = deepestLink
        }
    }
    
    static func withTop(link: Chainable, f: (Chainable) -> Void) {
        withQueue {
            var topLink: Chainable = link
            while let nextLink = topLink.parent {
                topLink = nextLink
            }
            f(topLink)
        }
    }
    
    static func withBottom(link: Chainable, f: (Chainable) -> Void) {
        withQueue {
            var bottomLink: Chainable = link
            while let nextLink = bottomLink.child {
                bottomLink = nextLink
            }
            
            f(bottomLink)
        }
    }
}



