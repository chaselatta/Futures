//
//  FutureExtensions.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public struct Futures {
    
    public static func collect<T>(futures: [Future<T>]) -> Future<[T]> {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "collect-queue")
        
        let p = Promise<[T]>()
        var results: [T?] = Array(repeating: nil, count: futures.count)
        var firstError: ErrorProtocol? = nil
        
        for (idx, f) in futures.enumerated() {
            group.enter()
            f.respond { result in
                queue.sync {
                    switch result {
                    case .satisfied(let v):
                        results[idx] = v
                    case .failed(let e):
                        if firstError == nil {
                            firstError = e
                            p.fail(error: e)
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            let values = results.flatMap { $0 }
            if values.count == futures.count {
                p.succeed(value: values)
            }
        }
        
        return p
    }
    
}
