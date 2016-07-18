//
//  Future.swift
//  Futures
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

enum FutureError: ErrorProtocol {
    
    /// Represents a failure due to an empty optional
    case optionalFailure
    
    /// Represents an error that occurs when `Future.by` fails
    case byTimeout
}

public class Future<Element> {
    
    /// Returns a Future that is fulfilled by the given value
    ///
    /// - Parameter value: the value that will satisfy they future
    /// - Returns: a satisfied `Future`
    public final class func value(_ value: Element) -> Future<Element> {
        return Promise.succeeded(value: value)
    }
    
    /// Returns a Future that is failed with the given error
    /// - Parameter error: the error that will fail they future
    /// - Returns: a failed `Future`
    public final class func error(_ error: ErrorProtocol) -> Future<Element> {
        return Promise.failed(error: error)
    }
    
    /// Returns a Future that will succeed if the optional is non-nil 
    /// and will fail if the `FutureError.optionalFailure` if it is nil
    ///
    /// - Parameter value: the value that will satisfy they future
    /// - Returns: a satisfied or failed Future
    public final class func optional(_ value: Element?) -> Future<Element> {
        if let v = value {
            return .value(v)
        } else {
            return .error(FutureError.optionalFailure)
        }
    }
    
    /// Returns a Future that will succeed if the optional function does not throw
    /// and will propogate the error that is thrown
    ///
    /// - Parameter throwable: the function to execute to get the value
    /// - Returns: a satisfied or failed Future Future
    public final class func throwable(throwable f: @noescape () throws -> Element) -> Future<Element> {
        do {
            return .value(try f())
        } catch {
            return .error(error)
        }
    }
    
    /// Returns a Future that will succeed with the given value at the specified time
    ///
    /// - Parameter when: the time to fulfill the future
    /// - Parameter value: The value which will satisfy the future
    /// - Returns: the future which will be fulfilled
    public final class func after(when time: DispatchTime, value: Element) -> Future<Element> {
        let p = Promise<Element>()
        DispatchQueue.global(attributes: [.qosUserInitiated]).after(when: time) {
            p.succeed(value: value)
        }
        return p
    }
    
    /// The initializer for a Future.
    /// - Note: Futures should not be created directly, use the class methods instead.
    public init() {}
    
    /// poll checks to see if the Future is complete,
    /// returns nil if the value is not fulfilled and 
    /// a Result if it has been fulfilled.
    ///
    /// This is most likely not the method you are looking for
    public func poll() -> Result<Element>? {
        fatalError("poll is an abstract method")
    }
    
    /// cancel will send a signal to the future and up the
    /// chain of futures telling them that they should attempt
    /// to cancel. Calling this method does not guarantee that
    /// the future will be cancelled. The provider of the future
    /// can determine whether the onSuccess/onFailure methods
    /// are invoked based on cancellation
    public func cancel() { /* Intentionally Blank */ }
    
    // MARK: Side Effects
    
    /// executes the given function upon success
    /// - Parameter execute: the method to execute
    /// - Returns: a `Future` which can be used to chain on
    @discardableResult
    public func onSuccess(execute: (Element) -> Void) -> Future {
        return respond {
            $0.withValue(execute: execute)
        }
    }
    
    /// executes the given function upon failure
    /// - Parameter execute: the method to execute
    /// - Returns: a `Future` which can be used to chain on
    @discardableResult
    public func onError(execute f: (ErrorProtocol) -> Void) -> Future {
        return respond {
            $0.withError(execute: f)
        }
    }
    
    /// Subclasses should override this method to handle sideeffects.
    @discardableResult
    internal func respond(_ f: (Result<Element>) -> Void) -> Future {
        fatalError("respond is an abstract method")
    }
    
    // MARK: Transformations
    
    /// converts the successful future to a new Future
    /// - Parameter transform: the method to transform the given element
    /// - Returns: a transformed future
    public func map<T>(transform: (Element) -> T) -> Future<T> {
        fatalError("map is abstract")
    }
    
    /// converts the successful future to a flattened Future
    /// - Parameter transform: the method to transform the given element
    /// - Returns: a transformed future
    public func flatMap<T>(transform: (Element) -> Future<T>) -> Future<T> {
        fatalError("flatMap is abstract")
    }
    
    /// executes the given transform upon failure of the future
    /// - Parameter transform: the method to transform the given error
    /// - Returns: a transformed future
    public func rescue(transform: (ErrorProtocol) -> Future<Element>) -> Future<Element> {
        fatalError("rescue is abstract")
    }
    
    /// requires that the future is successful by the given time
    /// - Parameter when: the time that the future should succeed by
    /// - Returns: a `Future` which will fail if not successful by the given time
    public func by(when: DispatchTime) -> Future<Element> {
        fatalError("by is abstract")
    }
}

