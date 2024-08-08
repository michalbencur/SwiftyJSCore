//
//  JSAsyncSwiftWrapper.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 08.08.24.
//

@preconcurrency import JavaScriptCore

public func wrapAsyncInJSPromise<T: Encodable>(closure: @Sendable @escaping () async throws -> T) -> JSValue {
    guard let context = JSContext.current() else {
        fatalError("context not available anymore")
    }
    var resolveRef: JSValueRef?
    var rejectRef: JSValueRef?
    let promiseRef = JSObjectMakeDeferredPromise(context.jsGlobalContextRef, &resolveRef, &rejectRef, nil)
    let resolve = JSValue(jsValueRef: resolveRef, in: context)
    let reject = JSValue(jsValueRef: rejectRef, in: context)
    let promise = JSValue(jsValueRef: promiseRef, in: context)
    Task {
        do {
            let result = try await closure()
            let json = try convertToJSCoreCompatible(result)
            resolve?.call(withArguments: [json])
        } catch {
            reject?.call(withArguments: [error.localizedDescription])
        }
    }
    return promise!
}
