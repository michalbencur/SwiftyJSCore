//
//  JSTypes.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 12.08.23.
//

@preconcurrency import JavaScriptCore

public protocol JSLogger: Sendable {
    func log(_ string: String)
}

public enum JSError: Error {
    case missingFunction, functionCallFailed, missingObject, typeError
    case exception(name: String, message: String)
    case promise(value: JSValue)
    case json(description: String)
    
    public var errorDescription: String? {
        switch self {
        case .exception(let name, let message):
            return "JSError \(name): \(message)"
        case .promise(let value):
            return "JSError \(value.debugDescription)"
        case .json(let description):
            return "JSError \(description)"
        case .missingFunction, .functionCallFailed, .missingObject, .typeError:
            return "JSError \(self.localizedDescription)"
        }
    }
}

public protocol JSConvertable {
    associatedtype T
    static func js_convert(_ value: JSValue) throws -> T
}

public typealias JSFetchType = @Sendable (URLRequest) async throws -> (Data, URLResponse)
