//
//  JSAsyncSwiftWrapper.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 08.08.24.
//

import JavaScriptCore

fileprivate class ClosureWrapper<T>: @unchecked Sendable {
    let closure: () async throws -> T
    init(closure: @escaping () async throws -> T) {
        self.closure = closure
    }
    func call() async throws -> T {
        return try await closure()
    }
}

public func wrapAsyncInJSPromise<T: Encodable>(closure: @escaping () async throws -> T) -> JSValue {
    guard let context = JSContext.current() else {
        fatalError("JSContext not available.")
    }
    
    let wrapper = ClosureWrapper(closure: closure)
    let (promiseHolder, promise) = JSPromiseHolder.create(context: context)
    
    Task.detached {
        do {
            let result = try await wrapper.call()
            let json = try convertToJSCoreCompatible(result)
            
            await promiseHolder.resolve(withArguments: [json])
        } catch {
            await promiseHolder.reject(withDescription: error.localizedDescription)
        }
    }
    return promise
}
