# SNNet

SNNet is a lightweight library that allows developers to write network client applications for iOS easiliy and efficiently.

## Syntax

To issue an HTTP GET request, use *SNNet.get* function like this (*params* is optional):

```
SNNet.get("https://www.google.com/webhp", params: [ "q":"Hello World" ]) { (url, err) -> (Void) in
    if let error = err {
        // Handle error
        ...
    } else {
        // Process the GET result in a file specified by url
        ...
    }
}
```

If you have only one server to access (or a server to access often), you may choose to specify the root URL at *SNNet.apiRoot* so that you can use relative URLs like below. Please be aware that *SNNet.apiRoot* is global and thread unsafe.

```
SNNet.apiRoot = NSURL(string:"https://www.google.com")!
SNNet.get("/webhp", params: [ "q":"Hello World" ]) { (url, err) -> (Void) in
    ...
}
```

It also supports HTTP POST, PUT and DELETE. Use *post*, *put*, and *delete* functions respectedly. 

## Test

1. Run the test serer. "node test/SNNet/server/index.js"
2. Open the project test/SNNet/SNNet.xcodeproj with xCode
3. Build & run it under one of iOS emulator
