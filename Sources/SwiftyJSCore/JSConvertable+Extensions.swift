//
//  JSConvertable+Extensions.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 12.08.23.
//

import JavaScriptCore

extension String: JSConvertable {
    public static func js_convert(_ value: JSValue) throws -> String {
        guard value.isString else {
            throw JSError.typeError
        }
        return value.toString()
    }
}

extension Bool: JSConvertable {
    public static func js_convert(_ value: JSValue) throws -> Bool {
        guard value.isBoolean else {
            throw JSError.typeError
        }
        return value.toBool()
    }
}

extension Int: JSConvertable {
    public static func js_convert(_ value: JSValue) throws -> Int {
        guard value.isNumber else {
            throw JSError.typeError
        }
        return Int(value.toInt32())
    }
}

extension Double: JSConvertable {
    public static func js_convert(_ value: JSValue) throws -> Double {
        guard value.isNumber else {
            throw JSError.typeError
        }
        return value.toDouble()
    }
}
