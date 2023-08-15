# SwiftyJSCore

*SwiftyJSCore* wraps *JavaScriptCore* Framework and provides a convenient way
to call JavaScript functions from Swift.

*SwiftyJSCore* supports:
- asynchronous functions/promises mapped from JS to Swift
- encoding and decoding `Codable` types in both directions
- exception handling

### Example

JavaScript:
```javascript
var testString = () => {
    return "Foobar";
}
var testAsync = async (arg) => {
    return { "id": arg.id, "name": "Test" }
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
