//
//  SwiftDataTests.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 08.08.24.
//

import XCTest
import JavaScriptCore
@testable import SwiftyJSCore

@objc protocol JSDatabaseAPIProtocol: JSExport {
    @objc func fetchUser(_ id: Int) -> JSValue
}

final class JSDatabaseAPI: NSObject, JSDatabaseAPIProtocol {
    let db = DatabaseAPI()
    
    @objc func fetchUser(_ id: Int) -> JSValue {
        return wrapAsyncInJSPromise {
            return try self.db.fetchUser(id: id)
        }
    }
}

final class SwiftDataTests: XCTestCase {
    
    let logger = Logger()
    var interpreter: JSInterpreter!
    
    override func setUp() async throws {
        if let _ = interpreter {
            return
        }
        interpreter = try JSInterpreter(logger: logger)
        let url = Bundle.module.url(forResource: "swift-data", withExtension: "js")!
        try await interpreter.evaluateFile(url: url)
    }
    
    func testUserPosts() async throws {
        let db = JSDatabaseAPI()
        let posts: [Post] = try await interpreter.call(function: "fetchPostsForUser", arguments: [1, db])
        XCTAssertEqual(posts.count, 4)
        XCTAssertEqual(posts.map({ $0.title }).sorted(), ["Fall", "Spring", "Summer", "Winter"])
    }
}
