//
//  JSInternal.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 13.08.23.
//

import JavaScriptCore

extension JSValue {
    public func js_convert<T: Decodable>() throws -> T {
        guard let json = context.globalObject.objectForKeyedSubscript("JSON"),
              let stringify = json.objectForKeyedSubscript("stringify"),
              !stringify.isUndefined else {
            fatalError("JSON.stringify not found")
        }
        
        guard let jsonString = stringify.call(withArguments: [self]).toString(),
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
