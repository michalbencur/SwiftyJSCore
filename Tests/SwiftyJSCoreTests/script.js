console.log("JS loading")

var testNoReturnValue = () => {
    console.log("testNoReturnValue called");
}

var testString = () => {
    return "Foobar";
}

var testArgument = (arg) => {
    return arg.getName();
}

var testAsync = async (arg) => {
    return {
        "id": arg.id,
        "name": "Test"
    }
}

var testException = async () => {
    throw new TypeError("TestError");
    return 1;
}
