//
//  FetchTests.swift
//  
//
//  Created by Michal Bencur on 15.08.23.
//

import XCTest
@testable import SwiftyJSCore

final class FetchTests: XCTestCase {

    var interpreter: JSInterpreter!
    var lastRequest: URLRequest?
    
    override func setUp() async throws {
        if let _ = interpreter {
            return
        }
        interpreter = try await JSInterpreter(fetch: { [weak self] request in
            self?.lastRequest = request

            let responseJSON = "{ \"id\": 123, \"name\": \"Foobar\" }"
            let statusCode = request.url?.path == "/test1.json" ? 200 :  201
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "2.0", headerFields: ["X-Custom" : "SwiftyJSCore"])!
            return (responseJSON.data(using: .utf8)!, response)
        })
        let url = Bundle.module.url(forResource: "script", withExtension: "js")!
        try await interpreter.evaluateFile(url: url)
    }

    func testFetch() async throws {
        let n: Int = try await interpreter.call(function: "testFetch")
        XCTAssert(n == 123)
        XCTAssertEqual(lastRequest!.httpMethod, "GET")
    }
    
    func testPOSTFetch() async throws {
        let string: String = try await interpreter.call(function: "testPOSTFetch")
        XCTAssert(string == "Foobar")
        XCTAssertEqual(lastRequest?.httpMethod, "POST")
        XCTAssertNotNil(lastRequest?.httpBody)
        XCTAssertEqual(lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
    
    func testFetchError() async throws {
        do {
            let _: String = try await interpreter.call(function: "testFetchMissingArguments")
            XCTFail("expected exception not thrown")
        } catch JSError.exception(let name, let message) {
            XCTAssertEqual(name, "Error")
            XCTAssertEqual(message, "fetch: missing arguments")
            return
        }
    }
}
