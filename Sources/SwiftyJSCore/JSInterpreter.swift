//
//  JSInterpreter.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 11.08.23.
//

import Foundation
import JavaScriptCore

public actor JSInterpreter {
    
    let logger: JSLogger
    var context: JSContext!

    public init(logger: JSLogger = JSConsoleLogger()) async throws {
        logger.log("JSInterpreter init")
        self.logger = logger
        self.context = JSContext()
        try await setupExceptionHandler()
        try await setupGlobal()
        try await setupConsole()
    }

    deinit {
        logger.log("JSInterpreter deinit")
    }
    
    public func evaluateFile(url: URL) async throws {
        let code = try String(contentsOf: url, encoding: .utf8)
        context.exception = nil
        _ = context.evaluateScript(code, withSourceURL: URL(string: url.lastPathComponent))
        try handleException(function: "evaluateFile \(url.lastPathComponent)")
    }

    public func setObject(_ object: Any!, forKey key: String) async throws {
        context.setObject(object, forKeyedSubscript: key as NSString)
    }
    
    public func call<T: JSConvertable>(function: String, arguments: [Any] = []) async throws -> T {
        guard let fn = javascriptObject(name: function) else {
            throw JSError.missingFunction
        }
        context.exception = nil
        guard let value = fn.call(withArguments: arguments) else {
            throw JSError.functionCallFailed
        }
        let valueAfterPromise = try await waitForPromise(value)
        try handleException(function: function)
        return try T.js_convert(valueAfterPromise) as! T
    }

    public func eval<T: JSConvertable>(code: String) async throws -> T {
        context.exception = nil
        guard let value = context.evaluateScript(code) else {
            throw JSError.functionCallFailed
        }
        let valueAfterPromise = try await waitForPromise(value)
        try handleException(function: "eval")
        return try T.js_convert(valueAfterPromise) as! T
    }

    public func call(function: String, arguments: [Any] = []) async throws {
        _ = try await call(function: function, arguments: arguments) as JSVoid
    }

    public func eval(code: String) async throws {
        _ = try await eval(code: code) as JSVoid
    }

    // MARK: -
    
    private func handleException(function: String) throws {
        if let exception = context.exception {
            throw Self.error(from: exception)
        }
    }
    
    private static func error(from exception: JSValue) -> JSError {
        let name = exception.objectForKeyedSubscript("name").toString()
        let message = exception.objectForKeyedSubscript("message").toString()
        return JSError.exception(
            name: name ?? "undefined",
            message: message ?? "undefined")
    }
    
    private func waitForPromise(_ value: JSValue) async throws -> JSValue {
        if value.toString() != "[object Promise]" {
            return value
        }
        return try await withUnsafeThrowingContinuation({ continuation in
            let onResolved: @convention(block) (JSValue) -> Void = {
                continuation.resume(returning: $0)
            }
            let onError: @convention(block) (JSValue) -> Void = {
                continuation.resume(throwing: Self.error(from: $0))
            }
            value.invokeMethod("then", withArguments: [unsafeBitCast(onResolved, to: JSValue.self)])
            value.invokeMethod("catch", withArguments: [unsafeBitCast(onError, to: JSValue.self)])
        })
    }
    
    private func javascriptObject(name: String) -> JSValue? {
        var object = context.globalObject
        for key in name.split(separator: ".") {
            if let o = object?.objectForKeyedSubscript(key), !o.isUndefined {
                object = o
            } else {
                return nil
            }
        }
        return object
    }
    
    // MARK: -
        
    private func setupGlobal() async throws {
        _ = context.evaluateScript("""
                var global = this;
                var window = this;
            """)
    }
    
    private func setupConsole() async throws {
        for method in ["log", "trace", "info", "warn", "error", "dir"] {
            let logger = logger
            let consoleFunc: @convention(block) () -> Void = {
                let message = JSContext.currentArguments()!.map { "\($0)"}.joined()
                logger.log("\(method): \(message)")
            }
            let console = context.objectForKeyedSubscript("console")
            console?.setObject(unsafeBitCast(consoleFunc, to: AnyObject.self), forKeyedSubscript: method as NSString)
        }
    }
    
    private func setupExceptionHandler() async throws {
        let logger = logger
        let handler: ((JSContext?, JSValue?) -> Void) = { context, exception in
            
            context?.exception = exception
            
            if let exception = exception,
               let stacktrace = exception.objectForKeyedSubscript("stack") {
                logger.log("error: \(exception) at \(stacktrace)")
            } else if let exception = exception {
                logger.log("error: \(exception)")
            } else {
                logger.log("error: nil")
            }
        }
        context.exceptionHandler = handler
    }
}
