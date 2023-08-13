//
//  JSInternal.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 13.08.23.
//

import JavaScriptCore

struct JSVoid: JSConvertable {
    public static func js_convert(_ value: JSValue) -> JSVoid { return JSVoid() }
}
