/*:
[Previous](@previous)
****
# Creating Futures
The base class for working with Futures is the `Future` class. It is not common to create a `Future` instance directly as they are generally vended via an asynchronous function, however, a `Future` can be created by using the `Future.value()` or `Future.error` methods. These methods will create a satisfied future. Check the `Future` class for various other class functions which allow for the creation of `Future`s.
 */
import Futures

// Create a future that is satisfied with a value
let satisfiedFuture = Future.value(1)

// Create a future that is satisfied with an error
let failedFuture = Future<Int>.error(ExampleError.generic)


/*:
****
# Side Effects 
Futures can have side effects applied to them which will be executed when the Future is satisifed by either an error or a value. Side effects which are added to an already satisfied Future will be executed immediately.
 
The first side effect is the `onSuccess(execute:)` method which will execute the given block when the Future is satisfied with a value.
 */
satisfiedFuture.onSuccess { value in
//    showValue(value)
}

failedFuture.onSuccess { value in
    // This code will never be executed because the future is already failed
}

/*:
The second side effect is the `onError(execute:)` method which will execute the given block when the Future is satisfied with an error.
 */
failedFuture.onError { error in
//    showValue(error)
}

satisfiedFuture.onError { error in
    // This code will never be executed because the future has already succeeded
}

/*:
****
# Transforms
The power of Futures lies in their transformations. Futures can be transformed using various functions which will only be applied after they have been fulfilled. Functions like `map` and `flatMap` will be applied after the future has a value set on it, whereas, functions like `rescue` will only be applied when the future has an error set on it.
 */

let intFuture = Future.value(1)
let stringFuture = intFuture.map { String($0) }
stringFuture.onSuccess { _ in
//    showValue($0)
}

let newFuture = intFuture.flatMap { _ in Future.value("hello, world") }
newFuture.onSuccess { _ in
//    showValue($0)
}

let rescuedFuture = Future<String>.error(ExampleError.generic).rescue { _ in Future.value("Hello, world") }
rescuedFuture.onSuccess { _ in
//    showValue($0)
}

/*:
****
# Cancellation
Futures may be cancelled by calling the `cancel` method on the given future. Calling cancel on the future will walk up the chain of futures and call `cancel` on each one as it goes. Cancellation is only a signal to the producer of the `Future` of your intent to cancel, it is up to the producer to actually cancel the work that the `Future` is representing.
*/
let futureA = Future.value(1)
let futureB = futureA.map { Array(repeating: "", count: $0) }

futureB.cancel()

//: [Previous](@previous) | [Next](@next)
