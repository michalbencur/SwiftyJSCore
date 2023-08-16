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
    let fetch: JSFetchType
    let context: JSContext

    public init(logger: JSLogger = JSConsoleLogger(), fetch: @escaping JSFetchType = jsFetch) async throws {
        logger.log("JSInterpreter init")
        self.logger = logger
        self.fetch = fetch
        self.context = JSContext()
        try await setupExceptionHandler()
        try await setupGlobal()
        try await setupConsole()
        try await setupFetch()
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
    
    public func eval<T: Decodable>(_ code: String) async throws -> T {
        let value = try await _eval(code: code)
        return try value.js_convert()
    }
    
    public func eval(_ code: String) async throws {
        _ = try await _eval(code: code)
    }
    
    public func call<T: Decodable>(function: String, arguments: [Any] = []) async throws -> T {
        let value = try await _call(function: function, arguments: arguments)
        return try value.js_convert()
    }
    
    public func call(function: String, arguments: [Any] = []) async throws {
        _ = try await _call(function: function, arguments: arguments)
    }

    // MARK: -
    
    private func _eval(code: String) async throws -> JSValue {
        context.exception = nil
        guard let value = context.evaluateScript(code) else {
            throw JSError.functionCallFailed
        }
        let valueAfterPromise = try await waitForPromise(value)
        try handleException(function: "eval")
        return valueAfterPromise
    }

    private func _call(function: String, arguments: [Any]) async throws -> JSValue {
        guard let fn = javascriptObject(name: function) else {
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
        return try arguments.map { try convertArgument($0) }
    }
    
    private func convertArgument(_ argument: Any) throws -> Any {
        if let argument = argument as? JSValue {
            return argument
        } else if let argument = argument as? JSExport {
            return argument
        } else if let argument = argument as? Encodable {
            return try argument.js_convertToPropertyList()
        } else if let argument = argument as? [String: Any] {
            return try argument.mapValues { try convertArgument($0) }
        }
        throw JSError.typeError
    }
    
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
}
