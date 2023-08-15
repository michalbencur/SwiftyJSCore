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
        throw Error("Response status not 200")
    }
    var json = await response.json();
    return json.name;
}
var testFetchMissingArguments = async () => {
    return await fetch();
}
