console.log("JS loading")
console.debug("Debug log")

var testNoReturnValue = () => {
    console.log("testNoReturnValue called");
}

var testString = () => {
    return "Foobar";
}

var testArgument = (arg) => {
    return arg.getName();
}

var testAsyncToPromise = async () => {
    return await testObject.getNameAfterTimeout();
}

var testArguments = (arg) => {
    if (arg.configuration.title != "Cool title") {
        throw TypeError("arg.configuration.title != Cool title")
    }
    if (arg.test.id != 123) {
        throw TypeError("arg.test.id != 123")
    }
}

var testAsync = async (arg) => {
    return new Promise(resolve => resolve({ "id": arg.id, "name": "Test" }));
};

var testException = async () => {
    throw new TypeError("TestError");
    return 1;
}

var testFetch = async () => {
    var response = await fetch("http://domain.net/test1.json");
    if (response.status != 200) {
        throw Error("Response status not 200")
    }
    if (!response.ok) {
        throw Error("Response not OK")
    }
    if (response.url != "http://domain.net/test1.json") {
        throw Error("Response URL invalid")
    }
    var json = await response.json();
    return json.id;
}
var testPOSTFetch = async () => {
    var response = await fetch("http://domain.net/test2.json", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ "id": 123, "name": "Foobar" })
    });
    if (response.status != 201) {
        throw Error("Response status not 201")
    }
    var json = await response.json();
    return json.name;
}
var testFetchText = async () => {
    var response = await fetch("http://domain.net/test1.json");
    if (response.status != 200) {
        throw Error("Response status not 200")
    }
    if (!response.ok) {
        throw Error("Response not OK")
    }
    var text = await response.text();
    return text;
}
var testFetchMissingArguments = async () => {
    return await fetch();
}
