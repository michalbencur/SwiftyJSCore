import XCTest
@testable import SwiftyJSCore

struct TestEntity: Codable {    
    let id: Int
    let name: String
}

final class SwiftyJSCoreTests: XCTestCase {
    
    let logger = Logger()
    var interpreter: JSInterpreter!
    
    override func setUp() async throws {
        if let _ = interpreter {
            return
        }
        interpreter = try await JSInterpreter(logger: logger)
        let url = Bundle.module.url(forResource: "script", withExtension: "js")!
        try await interpreter.evaluateFile(url: url)
    }
    
    func testNoReturnValue() async throws {
        try await interpreter.call(function: "testNoReturnValue")
        XCTAssertEqual(logger.lastLog, "log: testNoReturnValue called")
    }

    func testEval() async throws {
        logger.lastLog = ""
        try await interpreter.eval(code: "console.log(\"8+13=\", 8+13)")
        XCTAssert(logger.lastLog != nil)
        XCTAssertEqual(logger.lastLog, "log: 8+13=21")
    }
    
    func testSetObject() async throws {
        try await interpreter.setObject(13, forKey: "thirteen")
        let sum: Int = try await interpreter.eval(code: "thirteen+8")
        XCTAssertEqual(sum, 21)
    }

    func testReturnString() async throws {
        let string: String = try await interpreter.call(function: "testString")
        XCTAssertEqual(string, "Foobar")
    }

    func testAsync() async throws {
        let entity: TestEntity = try await interpreter.call(function: "testAsync")
        XCTAssertEqual(entity.id, 123)
        XCTAssertEqual(entity.name, "Test")
    }
    
    func testException() async throws {
        do {
            let _: Int = try await interpreter.call(function: "testException")
            XCTFail("expected exception not thrown")
        } catch JSError.exception(let name, let message) {
            XCTAssertEqual(name, "TypeError")
            XCTAssertEqual(message, "TestError")
            return
        }
    }
}
