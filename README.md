# SNNet

SNNet is a lightweight library that allows developers to write network client applications for iOS easiliy and efficiently.

## Syntax

To issue an HTTP GET request, use SNNet.get function like this (params is optional):

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

It also supports HTTP POST, PUT and DELETE. Use post, put, and delete functions respectedly. 
