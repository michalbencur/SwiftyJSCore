//
//  JSInterpreter+Fetch.swift
//  
//
//  Created by Michal Bencur on 15.08.23.
//

import Foundation
import JavaScriptCore

extension JSInterpreter {
    func setupFetch() throws {
        let fetch = self.fetch
        let fetchFunc: @convention(block) () -> JSValue = {
            let args = JSContext.currentArguments()!
            let context = JSContext.current()!
            
            guard (args.count > 0) else {
                context.exception = JSValue(newErrorFromMessage: "fetch: missing arguments", in: context)
                return JSValue.init(undefinedIn: context)
            }
            guard let urlValue = args[0] as? JSValue,
                  let urlString = urlValue.toString(),
                  let url = URL(string: urlString) else {
                context.exception = JSValue(newErrorFromMessage: "fetch: invalid URL", in: context)
                return JSValue.init(undefinedIn: context)
            }
            
            var request = URLRequest(url: url)
            if args.count > 1, let options = args[1] as? JSValue, options.isObject {
                update(request: &request, with: options)
            }
            
            let (promiseHolder, promise) = JSPromiseHolder.create(context: context)
            
            nonisolated(unsafe) let _context = context
            Task { @MainActor in
                do {
                    let (data, response) = try await fetch(request)
                    let fetchResponse = JSFetchResponse(data: data, response: response, context: _context)
                    await promiseHolder.resolve(withArguments: [fetchResponse])
                } catch (let error) {
                    await promiseHolder.reject(withDescription: error.localizedDescription)
                }
            }
            
            return promise
        }
        context.setObject(unsafeBitCast(fetchFunc, to: AnyObject.self), forKeyedSubscript: "fetch" as NSString)
    }
    
    func convertFetchResponse(data: Data, response: URLResponse) -> JSFetchResponse {
        return JSFetchResponse(data: data, response: response, context: context)
    }
}

private func update(request: inout URLRequest, with options: JSValue) {
    if options.hasProperty("method"), let method = options.forProperty("method"), method.isString {
        request.httpMethod = method.toString()
    }
    if options.hasProperty("cache"),
       let cacheValue = options.forProperty("cache"),
       cacheValue.isString,
       let cache = cacheValue.toString() {
        let policy: URLRequest.CachePolicy
        if (cache == "no-store" || cache == "reload") {
            policy = .reloadIgnoringLocalAndRemoteCacheData
        } else if (cache == "no-cache") {
            policy = .reloadRevalidatingCacheData
        } else if (cache == "force_cache") {
            policy = .returnCacheDataElseLoad
        } else if (cache == "only-if-cached") {
            policy = .returnCacheDataDontLoad
        } else {
            policy = .useProtocolCachePolicy
        }
        request.cachePolicy = policy
    }
    if options.hasProperty("headers"),
       let headersValue = options.forProperty("headers"),
       headersValue.isObject,
       let properties = headersValue.toDictionary() {
        for (key, value) in properties {
            if let key = key as? String,
               let value = value as? String {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
    }
    if options.hasProperty("body"),
       let bodyValue = options.forProperty("body"),
       bodyValue.isString {
        request.httpBody = bodyValue.toString().data(using: .utf8)
    }
}

// MARK: - Response

@objc protocol JSFetchResponseProtocol: JSExport {
    var ok: Bool { get }
    var status: Int { get }
    var url: String? { get }
    
    func json() -> JSValue
}

class JSFetchResponse: NSObject, JSFetchResponseProtocol, @unchecked Sendable {
    let data: Data
    let response: URLResponse
    weak var context: JSContext?

    var ok: Bool { (200...299).contains(status) }
    var status: Int { return (response as? HTTPURLResponse)?.statusCode ?? 500 }
    var url: String? { return response.url?.absoluteString }
    
    init(data: Data, response: URLResponse, context: JSContext) {
        self.data = data
        self.response = response
        self.context = context
        super.init()
    }
    
    @objc func json() -> JSValue {
        guard let context = context else {
            return JSValue.init()
        }
        let data = data
        return JSValue(newPromiseIn: context) { [weak context] resolve, reject in
            guard let context = context else {
                return
            }
            guard (!data.isEmpty) else {
                let exception = JSValue(newErrorFromMessage: "fetch: json() empty data", in: context)!
                reject?.call(withArguments: [exception])
                return
            }
            guard let json = context.globalObject.objectForKeyedSubscript("JSON"),
                  let parse = json.objectForKeyedSubscript("parse"),
                  !parse.isUndefined else {
                fatalError("JSON.parse not found")
            }

            guard let jsonString = String(data: data, encoding: .utf8),
                  let json = parse.call(withArguments: [jsonString]),
                  json.isObject else {
                let exception = JSValue(newErrorFromMessage: "fetch: json() failed", in: context)!
                reject?.call(withArguments: [exception])
                return
            }
            resolve?.call(withArguments: [json])
        }
    }
}
