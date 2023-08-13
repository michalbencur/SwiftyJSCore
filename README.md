# SwiftyJSCore

*SwiftyJSCore* wraps *JavaScriptCore* Framework and provides a convenient way to call JavaScript
functions from Swift, supporting asynchronous functions (Promise) and decoding values
to `Codable` types.

Example:

```javascript
var testString = () => {
    return "Foobar";
}

var testAsync = async () => {
    return {
        "id": 123,
        "name": "Test"
    }
}

var testException = async () => {
    throw new TypeError("TestError");
    return 1;
}
```

```swift
    let interpreter = try await JSInterpreter()
    try await interpreter.evaluateFile(url: jsURL)
    try await interpreter.eval(code: "console.log(\"8+13=\", 8+13)")

    try await interpreter.setObject(13, forKey: "thirteen")
    let sum: Int = try await interpreter.eval(code: "thirteen+8")
    assert(sum == 21)

    let string: String = try await interpreter.call(function: "testString")
    assert(string == "Foobar")

    let entity: TestEntity = try await interpreter.call(function: "testAsync")
    assert(entity.id == 123 && entity.name == "Test")

    do {
        let _: Int = try await interpreter.call(function: "testException")
    } catch JSError.exception(let name, let message) {
        assert(name, "TypeError")
        assert(message, "TestError")
    }
```
