//
//  InvocationContext.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public struct InvocationContext {
    
    public enum When {
        case sync
        case async
    }
    
    public let queue: DispatchQueue
    public let when: When
    
    public func execute(_ f: () -> Void) {
        switch when {
        case .sync:
            queue.sync(execute: f)
        case .async:
            queue.async(execute: f)
        }
    }
    
    public static func sync(on queue: DispatchQueue) -> InvocationContext {
        return InvocationContext(queue: queue, when: .sync)
    }
    
    public static func async(on queue: DispatchQueue) -> InvocationContext {
        return InvocationContext(queue: queue, when: .async)
    }
}
