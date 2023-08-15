//
//  JSTypes.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 12.08.23.
//

import JavaScriptCore

public protocol JSLogger {
    func log(_ string: String)
}

public enum JSError: Error {
    case missingFunction, functionCallFailed, missingObject, typeError
    case exception(name: String, message: String)
    case promise(value: JSValue)
    case json(description: String)
}

public protocol JSConvertable {
    associatedtype T
    static func js_convert(_ value: JSValue) throws -> T
}

public typealias JSFetchType = (URLRequest) async throws -> (Data, URLResponse)
