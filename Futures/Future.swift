//
//  Future.swift
//  Futures
//
//  Created by Chase Latta on 7/7/16.
//  Copyright © 2016 Chase Latta. All rights reserved.
//

import Foundation

//TODO: Need better error codes and domain
public let FutureOptionalFailureError = NSError(domain: "com.futures.future", code: 1, userInfo: nil)
public let FutureByTimeoutError = NSError(domain: "com.futures.future", code: 2, userInfo: nil)

public class Future<Element> {
    
    public final class func value(_ value: Element) -> Future<Element> {
        let p = Promise<Element>()
        p.succeed(value: value)
        return p
    }
    
    public final class func error(_ error: ErrorProtocol) -> Future<Element> {
        let p = Promise<Element>()
        p.fail(error: error)
        return p
    }
    
    public final class func optional(_ value: Element?, error: ErrorProtocol = FutureOptionalFailureError) -> Future<Element> {
        if let v = value {
            return .value(v)
        } else {
            return .error(error)
        }
    }
    
    public final class func throwable(throwable f: () throws -> Element) -> Future<Element> {
        do {
            return .value(try f())
        } catch {
            return .error(error)
        }
    }
    
    public final class func after(when time: DispatchTime, value: Element) -> Future<Element> {
        let p = Promise<Element>()
        DispatchQueue.global(attributes: [.qosUserInitiated]).after(when: time) {
            p.succeed(value: value)
        }
        return p
    }
    
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
    
    // MARK: Side effects
    
    @discardableResult
    public func onSuccess(context: InvocationContext? = nil, execute f: (Element) -> Void) -> Future {
        return respond {
            $0.withValue { v in
                self.with(context: context) { f(v) }
            }
        }
    }
    
    @discardableResult
    public func onError(context: InvocationContext? = nil, execute f: (ErrorProtocol) -> Void) -> Future {
        return respond {
            $0.withError { error in
                self.with(context: context) { f(error) }
            }
        }
    }
    
    private func with(context: InvocationContext?, execute f: () -> Void) {
        if let context = context {
            context.execute(f)
        } else {
            f()
        }
    }
    
    @discardableResult
    internal func respond(_ f: (Result<Element>) -> Void) -> Future {
        fatalError("respond is an abstract method")
    }
    
    // MARK: Transformations
    
    public func map<T>(f: (Element) -> T) -> Future<T> {
        fatalError("map is abstract")
    }
    
    public func flatMap<T>(f: (Element) -> Future<T>) -> Future<T> {
        fatalError("flatMap is abstract")
    }
    
    public func rescue(f: (ErrorProtocol) -> Future<Element>) -> Future<Element> {
        fatalError("rescue is abstract")
    }
    
    public func by(when: DispatchTime, error: ErrorProtocol = FutureByTimeoutError) -> Future<Element> {
        fatalError("by is abstract")
    }
}

