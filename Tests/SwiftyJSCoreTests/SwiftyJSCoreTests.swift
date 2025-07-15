import XCTest
import JavaScriptCore
@testable import SwiftyJSCore

struct TestEntity: Codable {
    let id: Int
    let name: String
}

@objc protocol TestObjectProtocol: JSExport {
    func getName() -> String
    func getNameAfterTimeout() -> JSValue
}

class TestObject: NSObject, TestObjectProtocol {
    @objc func getName() -> String {
        return "Ferdinand"
    }
    @objc func getNameAfterTimeout() -> JSValue {
        return wrapAsyncInJSPromise {
            try await Task.sleep(for: .seconds(1.0))
            return "Knuth"
        }
    }
}

final class SwiftyJSCoreTests: XCTestCase {
    
    let logger = Logger()
    var interpreter: JSInterpreter!
    
    override func setUp() async throws {
        if let _ = interpreter {
            return
        }
        interpreter = try JSInterpreter(logger: logger)
        let url = Bundle.module.url(forResource: "script", withExtension: "js")!
        try await interpreter.evaluateFile(url: url)
    }
    
    func testNoReturnValue() async throws {
        try await interpreter.call(function: "testNoReturnValue", arguments: [])
        XCTAssertEqual(logger.lastLog, "log: testNoReturnValue called")
    }
    
    func testEvaluate() async throws {
        logger.lastLog = ""
        try await interpreter.evaluate("console.log(\"8+13=\", 8+13)")
        XCTAssert(logger.lastLog != nil)
        XCTAssertEqual(logger.lastLog, "log: 8+13=21")
    }
    
    func testArguments() async throws {
        let test = TestEntity(id: 123, name: "Test")
        let arg = [
            "configuration": ["title": "Cool title"],
            "test": test
        ] as [String : Any]
        try await interpreter.call(function: "testArguments", arguments: [arg])
    }
    
    func testSetObject() async throws {
        try await interpreter.setObject(13, forKey: "thirteen")
        let sum: Int = try await interpreter.evaluate("thirteen+8")
        XCTAssertEqual(sum, 21)
    }
    
    func testReturnString() async throws {
        let string: String = try await interpreter.call(function: "testString", arguments: [])
        XCTAssertEqual(string, "Foobar")
    }
    
    func testJSExportArgument() async throws {
        let string: String = try await interpreter.call(function: "testArgument", arguments: [TestObject()])
        XCTAssertEqual(string, "Ferdinand")
        
    }
    
    func testAsync() async throws {
        let entity: TestEntity = try await interpreter.call(
            function: "testAsync",
            arguments: [TestEntity(id: 123, name: "Foobar")])
        
        XCTAssertEqual(entity.id, 123)
        XCTAssertEqual(entity.name, "Test")
    }

    @MainActor func testAsyncToPromise() async throws {
        let exp = expectation(description: "testAsyncToPromise calls async getNameAfterTimeout which sleeps for 1 second")
        Task {
            try await interpreter.setObject(TestObject(), forKey: "testObject")
            let name: String = try await interpreter.call(function: "testAsyncToPromise", arguments: [])
            XCTAssertEqual(name, "Knuth")
            exp.fulfill()
        }

        Task {
            let testString: String = try await interpreter.call(function: "testString", arguments: [])
            XCTAssertEqual(testString, "Foobar")
        }
        
        let result = await XCTWaiter.fulfillment(of: [exp], timeout: 1.5)
        XCTAssertEqual(result, XCTWaiter.Result.completed)
        
        // test JSInterpreter deallocation
        interpreter = nil
        XCTAssertEqual(logger.lastLog, "JSInterpreter deinit")
    }

    func testException() async throws {
        do {
            let _: Int = try await interpreter.call(function: "testException", arguments: [])
            XCTFail("expected exception not thrown")
        } catch JSError.exception(let name, let message, let stack) {
            XCTAssertEqual(name, "TypeError")
            XCTAssertEqual(message, "TestError")
            XCTAssert(!stack.isEmpty)
            XCTAssert(stack == "@script.js:34:24\ntestException@script.js:33:28")
            return
        }
    }
}
