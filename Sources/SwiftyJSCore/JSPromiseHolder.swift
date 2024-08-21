//
//  JSPromiseHolder.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 16.08.24.
//

@preconcurrency import JavaScriptCore

actor JSPromiseHolder {
    private let resolve: JSValue
    private let reject: JSValue
    private weak var context: JSContext?
    
    static func create(context: JSContext) -> (JSPromiseHolder, JSValue) {
        var resolveRef: JSValueRef!
        var rejectRef: JSValueRef!
        let promiseRef = JSObjectMakeDeferredPromise(context.jsGlobalContextRef, &resolveRef, &rejectRef, nil)
        let resolve: JSValue! = JSValue(jsValueRef: resolveRef, in: context)
        let reject: JSValue! = JSValue(jsValueRef: rejectRef, in: context)
        let promise: JSValue! = JSValue(jsValueRef: promiseRef, in: context)
        return (JSPromiseHolder(resolve: resolve, reject: reject, context: context), promise)
    }
    private init(resolve: JSValue, reject: JSValue, context: JSContext) {
        self.resolve = resolve
        self.reject = reject
        self.context = context
    }
    func resolve(withArguments arguments: [Any]) {
        resolve.call(withArguments: arguments)
    }
    func reject(withDescription description: String) {
        guard let context else {
            return
        }
        let exception = JSValue(newErrorFromMessage: description, in: context)!
        reject.call(withArguments: [exception])
    }
}
