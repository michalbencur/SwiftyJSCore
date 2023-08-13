console.log("JS loading")

var testNoReturnValue = () => {
    console.log("testNoReturnValue called");
}

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
