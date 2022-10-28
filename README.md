# Code Stack Trace

![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE.md)

A structure containing a manually callable stack trace.
Storing File Path, Function, and Line number.

This object was mainly created for debugging, allowing developers to follow code calls within their own code.

## Requirements

* Xcode 9+ (If working within Xcode)
* Swift 4.0+

## Usage

```swift
enum CodeError: Error {
    case someError(trace: CodeStackTrace)
}

// Start the Stack Trace
let stackTrace = CodeStackTrace()

func someFunction(argument: Int, stack: CodeStackTrace) throws {
    ... do code here, pass stack.stacking() to any additional functions
    throw CodeError.someError(trace: stack)
}

do {
    try someFunction(argument: 0, stack: stackTrace.stacking())
} catch CodeError.someError(trace: let stackTrace) {
    print("Some Error:\n" + stackTrace.map( { return $0.description } ).joined(separator: "\n))
} catch {
    // some other error occured
} 
```

## Author

* **Tyler Anger** - *Initial work* 

## License

*Copyright 2022 Tyler Anger*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[HERE](LICENSE.md) or [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
