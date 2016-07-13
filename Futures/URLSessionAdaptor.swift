//
//  URLSessionAdaptor.swift
//  Futures
//
//  Created by Chase Latta on 7/13/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

// A wrapper around the response for URLSession.dataTask methods
public struct DataTaskResponse {
    public let data: Data
    public let response: URLResponse
}

public typealias DataTaskCompletionHandler = (Data?, URLResponse?, NSError?) -> Void

public struct URLSessionAdaptor {
    
    /// Call this method to get a future and a completion handler which can be used
    /// to convert URLSession methods from callback based to Future based.
    ///
    ///     let url = URL(string: "https://www.example.com")!
    ///     let (f, c) = URLSessionAdaptor.future()
    ///
    ///     let task = URLSession.shared().dataTask(with: url, completionHandler: c)
    ///     task.resume()
    ///
    ///     f.onSuccess { v in ... } // v is a DataTaskResponse struct
    ///     f.onError { e in ... }
    ///
    public static func future() -> (Future<DataTaskResponse>, DataTaskCompletionHandler) {
        let promise = Promise<DataTaskResponse>()
        
        let handler = { (data: Data?, response: URLResponse?, error: NSError?) in
            if let error = error {
                promise.fail(error: error)
            } else if let data = data, response = response {
                let taskResponse = DataTaskResponse(data: data, response: response)
                promise.succeed(value: taskResponse)
            }
            fatalError("Should not get to this point") // do better than this
        }
        
        return (promise, handler)
    }
}
