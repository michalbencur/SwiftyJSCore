//
//  JSInterpreter.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 11.08.23.
//

import Foundation
@preconcurrency import JavaScriptCore

/// SwiftyJSCore's main API to control JavaScript virtual machine
public class JSInterpreter {
    
    let logger: JSLogger
    let fetch: JSFetchType
    let context: JSContext
    
    /// JavaScript execution takes place within a context, and all JavaScript values are tied to a context.
    /// - Parameters:
    ///   - logger: optional logger implementation, used for console.log calls
    ///   - fetch: optional fetch implementation, useful for unit tests
    public init(logger: JSLogger = JSConsoleLogger(), fetch: @escaping JSFetchType = jsFetch) throws {
        logger.log("JSInterpreter init")
        self.logger = logger
        self.fetch = fetch
        self.context = JSContext()
        try setupExceptionHandler()
        try setupGlobal()
        try setupConsole()
        try setupFetch()
    }

    deinit {
        logger.log("JSInterpreter deinit")
    }
    
    /// Load and evaluate JavaScript code
    /// - Parameter url: URL to a JavaScript script to load
    public func evaluateFile(url: URL) async throws {
        let code = try String(contentsOf: url, encoding: .utf8)
        context.exception = nil
        _ = context.evaluateScript(code, withSourceURL: URL(string: url.lastPathComponent))
        try handleException(function: "evaluateFile \(url.lastPathComponent)")
    }
    
    /// Set global variable in JavaScript context
    /// - Parameters:
    ///   - object: value to be set to
    ///   - key: variable name
    public func setObject(_ object: Any!, forKey key: String) async throws {
        context.setObject(object, forKeyedSubscript: key as NSString)
    }
    
    /// Evaluate JavaScript code
    /// - Parameter code: JavaScript code
    /// - Returns: returns result of the code execution, converted to a Decodable Swift class
    public func evaluate<T: Decodable>(_ code: String) async throws -> T {
        let value = try await _evaluate(code: code)
        return try value.js_convert()
    }
    
    /// Evaluate JavaScript code
    /// - Parameter code: JavaScript code
    public func evaluate(_ code: String) async throws {
        _ = try await _evaluate(code: code)
    }
    
    /// Calls JavaScript function. Supports keypath, for example for an object named "weather", you can call its method "getTemperature", use "weather.getTemperature" as function name.
    /// - Parameters:
    ///   - object: JSValue object to call function on. Defaults to JSC's context.globalObject
    ///   - function: Function name to call.
    ///   - arguments: Arguments to pass to a function. Encodable objects are converted to JavaScript objects.
    /// - Returns: returns result of the code execution, converted to a Decodable Swift class
    public func call<T: Decodable>(object: JSValue? = nil, function: String, arguments: [Any]) async throws -> T {
        let value = try await _call(rootObject: object, function: function, arguments: arguments)
        return try value.js_convert()
    }

    /// Calls JavaScript function. Supports keypath, for example for an object named "weather", you can call its method "getTemperature", use "weather.getTemperature" as function name.
    /// - Parameters:
    ///   - function: Function name to call.
    ///   - arguments: Arguments to pass to a function. Encodable objects are converted to JavaScript objects.
    /// - Returns: JSValue
    public func callReturningValue(function: String, arguments: [Any]) async throws -> JSValue {
        return try await _call(function: function, arguments: arguments)
    }

    /// Calls JavaScript function. Supports keypath, for example for an object named "weather", you can call its method "getTemperature", use "weather.getTemperature" as function name.
    /// - Parameters:
    ///   - function: Function name to call.
    ///   - arguments: Arguments to pass to a function. Encodable objects are converted to JavaScript objects.
    public func call(function: String, arguments: [Any] = []) async throws {
        _ = try await _call(function: function, arguments: arguments)
    }

    /// Calls JavaScript function. Supports keypath, for example for an object named "weather", you can call its method "getTemperature", use "weather.getTemperature" as function name.
    /// - Parameters:
    ///   - function: Function name to call.
    ///   - arguments: Arguments to pass to a function. Encodable objects are converted to JavaScript objects.
    public func call(object: JSValue, function: String, arguments: [Any] = []) async throws {
        _ = try await _call(rootObject: object, function: function, arguments: arguments)
    }

    // MARK: -
    
    private func _evaluate(code: String) async throws -> JSValue {
        context.exception = nil
        guard let value = context.evaluateScript(code) else {
            throw JSError.functionCallFailed
        }
        let valueAfterPromise = try await waitForPromise(value)
        try handleException(function: "evaluate")
        return valueAfterPromise
    }

    private func _call(rootObject: JSValue? = nil, function: String, arguments: [Any]) async throws -> JSValue {
        guard let fn = javascriptObject(rootObject: rootObject, name: function) else {
            throw JSError.missingFunction
        }
        let convertedArguments = try convertArguments(arguments: arguments)
        context.exception = nil
        guard let value = fn.call(withArguments: convertedArguments) else {
            throw JSError.functionCallFailed
        }
        let valueAfterPromise = try await waitForPromise(value)
        try handleException(function: function)
        return valueAfterPromise
    }

    private func convertArguments(arguments: [Any]) throws -> [Any] {
        return try arguments.map { try convertToJSCoreCompatible($0) }
    }
    
    private func handleException(function: String) throws {
        if let exception = context.exception {
            throw Self.error(from: exception)
        }
    }
    
    private static func error(from exception: JSValue) -> JSError {
        let name = exception.objectForKeyedSubscript("name").toString() ?? "undefined"
        let message = exception.objectForKeyedSubscript("message").toString() ?? "undefined"
        let stack = exception.objectForKeyedSubscript("stack").toString() ?? "undefined"
        return JSError.exception(
            name: name,
            message: message,
            stack: stack)
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
    
    private func javascriptObject(rootObject: JSValue?, name: String) -> JSValue? {
        var object = rootObject ?? context.globalObject
        assert(object != nil)
        for key in name.split(separator: ".") {
            if let o = object?.objectForKeyedSubscript(key), !o.isUndefined {
                object = o
            } else {
                return nil
            }
        }
        return object
    }
}
