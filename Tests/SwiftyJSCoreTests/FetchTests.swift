//
//  FetchTests.swift
//  
//
//  Created by Michal Bencur on 15.08.23.
//

import XCTest
@testable import SwiftyJSCore

actor TestRequest {
    static let shared = TestRequest()
    var last: URLRequest?
    init() {}
    func set(last: URLRequest) {
        self.last = last
    }
}

final class FetchTests: XCTestCase {

    var interpreter: JSInterpreter!
        
    override func setUp() async throws {
        if let _ = interpreter {
            return
        }
        interpreter = try await JSInterpreter(fetch: { request in
            await TestRequest.shared.set(last: request)

            let responseJSON = "{ \"id\": 123, \"name\": \"Foobar\" }"
            let statusCode = request.url?.path == "/test1.json" ? 200 :  201
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "2.0", headerFields: ["X-Custom" : "SwiftyJSCore"])!
            return (responseJSON.data(using: .utf8)!, response)
        })
        let url = Bundle.module.url(forResource: "script", withExtension: "js")!
        try await interpreter.evaluateFile(url: url)
    }

    func testFetch() async throws {
        let n: Int = try await interpreter.call(function: "testFetch", arguments: [])
        XCTAssert(n == 123)
        let lastRequest = await TestRequest.shared.last
        XCTAssertNotNil(lastRequest)
        XCTAssertEqual(lastRequest?.httpMethod, "GET")
    }
    
    func testPOSTFetch() async throws {
        let string: String = try await interpreter.call(function: "testPOSTFetch", arguments: [])
        XCTAssert(string == "Foobar")
        let lastRequest = await TestRequest.shared.last
        XCTAssertNotNil(lastRequest)
        XCTAssertEqual(lastRequest?.httpMethod, "POST")
        XCTAssertNotNil(lastRequest?.httpBody)
        XCTAssertEqual(lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
    
    func testFetchError() async throws {
        do {
            let _: String = try await interpreter.call(function: "testFetchMissingArguments", arguments: [])
            XCTFail("expected exception not thrown")
        } catch JSError.exception(let name, let message) {
            XCTAssertEqual(name, "Error")
            XCTAssertEqual(message, "fetch: missing arguments")
            return
        }
    }
}
