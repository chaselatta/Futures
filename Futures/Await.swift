//
//  Await.swift
//  Futures
//
//  Created by Chase Latta on 7/18/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

public struct Await {
    
    public static func result<T>(future: Future<T>) throws -> T {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var valueMaybe: T? = nil
        var errorMaybe: Error? = nil
        
        future.respond { result in
            result.withValue { valueMaybe = $0 }
            result.withError { errorMaybe = $0 }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let value = valueMaybe {
            return value
        } else if let error = errorMaybe {
            throw error
        }
        
        fatalError()
    }
}
