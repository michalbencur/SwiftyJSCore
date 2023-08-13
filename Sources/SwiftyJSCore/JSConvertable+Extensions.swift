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

extension JSConvertable where T: Decodable {
    public static func js_convert(_ value: JSValue) throws -> T {
        guard let json = value.context.globalObject.objectForKeyedSubscript("JSON"),
              let stringify = json.objectForKeyedSubscript("stringify"),
              !stringify.isUndefined else {
            fatalError("JSON.stringify not found")
        }
        
        guard let jsonString = stringify.call(withArguments: [value]).toString(),
              let jsonData = jsonString.data(using: .utf8)
        else {
            throw JSError.json(description: "JSON.stringify failed")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData)
        } catch let error {
            throw JSError.json(description: "\(error)")
        }
    }
}
