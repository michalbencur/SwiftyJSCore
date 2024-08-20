# SwiftyJSCore

*SwiftyJSCore* wraps *JavaScriptCore* Framework and provides a convenient way
to call JavaScript functions from Swift.

*SwiftyJSCore* supports:
- asynchronous functions/promises mapped in both directions
- encoding and decoding `Codable` types in both directions
- exception handling
- basics of Fetch API supporting json() response
- Swift 6 mode

> [!NOTE]
> If your application targets iOS and performance is important to you, consider using WKWebView.
> WKWebView, running in a separate process not having security issues, uses JIT compiler making JS
> considerably faster compared to JavaScriptCore.

### Example

SwiftyJSCore's APIs is concurrent, abstracting functions calls and promises to the same async API.

JavaScript:
```javascript
var testString = () => {
    return "Foobar";
}
var testAsync = async (arg) => {
    return new Promise(resolve => resolve({ "id": arg.id, "name": "Test" }));
}
var testException = async () => {
    throw new TypeError("TestError");
}
```

Swift:
```swift
let interpreter = try await JSInterpreter()
try await interpreter.evaluateFile(url: jsURL)
try await interpreter.eval("console.log(\"8+13=\", 8+13)")

try await interpreter.setObject(13, forKey: "thirteen")
let sum: Int = try await interpreter.eval("thirteen+8")
assert(sum == 21)

let string: String = try await interpreter.call(function: "testString")
assert(string == "Foobar")
```

You can pass `Codable` entities and typical JavaScriptCore @objc/NSObject classes as function arguments.
Return values map to Swift primitives or `Codable`.

```swift
struct TestEntity: Codable {
    let id: Int
    let name: String
}

let entity: TestEntity = try await interpreter.call(
    function: "testAsync",
    arguments: [TestEntity(id: 123, name: "Foobar")])
assert(entity.id == 123 && entity.name == "Test")

do {
    let _: Int = try await interpreter.call(function: "testException")
} catch JSError.exception(let name, let message) {
    assert(name, "TypeError")
    assert(message, "TestError")
}
```

### Swift async calls wrapped as JavaScript Promises

Use `wrapAsyncInJSPromise` in your JSExport classes to export Swift async functions to JavaScript.

Check unit tests for an example using SwiftData.

JS
```
var fetchPostsForUser = async (id, db) => {
    const user = await db.fetchUser(id);
    return user.posts;
};
```

Swift
```
@objc protocol JSDatabaseAPIProtocol: JSExport {
    @objc func fetchUser(_ id: Int) -> JSValue
}

class JSDatabaseAPI: NSObject, JSDatabaseAPIProtocol {
    let db = DatabaseAPI()
    
    @objc func fetchUser(_ id: Int) -> JSValue {
        return wrapAsyncInJSPromise {
            return try await self.db.fetchUser(id: id)
        }
    }
}
```
