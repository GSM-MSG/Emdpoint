# Emdpoint

This library is a tool for handling different types of HTTP requests in a convenient way.

<br>

## Constents
- [Emdpoint](#emdpoint)
  - [Constents](#constents)
  - [Requirements](#requirements)
  - [Overview](#overview)
  - [Communication](#communication)
  - [Installation](#installation)
    - [Swift Package Manager](#swift-package-manager)
    - [Manually](#manually)
  - [Usage](#usage)
    - [Quick Start](#quick-start)

<br>

## Requirements
- iOS 13.0+ / tvOS 13.0+ / macOS 10.15+ / watchOS 7.0+
- Swift 5.4+

<br>

## Overview
Emdpoint is a library that provides a convenient way to handle HTTP requests.

<br>

## Communication
- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.

<br>

## Installation
### Swift Package Manager
[Swift Package Manager](https://www.swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate `Emdpoint` into your Xcode project using Swift Package Manager, add it to the dependencies value of your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/GSM-MSG/Emdpoint.git", .upToNextMajor(from: "1.0.0"))
]
```

### Manually
If you prefer not to use either of the aforementioned dependency managers, you can integrate MSGLayout into your project manually.

<br>

## Usage

### Quick Start
```swift
import Emdpoint

enum JsonEndpoint {
    case todos
}

extension JsonEndpoint: EndpointType {
    var baseURL: URL {
        URL(string: "https://jsonplaceholder.typicode.com/")!
    }
    
    var route: Route {
        .get("todos")
    }
    
    var task: HTTPTask {
        .requestPlain
    }
}

import Combine
import UIKit

final class ViewController: UIViewController {
    var bag = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        let client = EmdpointClient<TestEndpoint>()

        // MARK: - Async/Await
        Task {
            let data = try await client.request(.todos).data
            let prettyData = try? JSONSerialization.jsonObject(with: data)
            print(prettyData)
        }

        // MARK: - Combine
        client.requestPublisher(.todos)
            .sink { completion in
                switch completion {
                case .finished:
                    print("finished")
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { data in
                print(data)
            }
            .store(in: &bag)

        // MARK: - Completion Closure
        client.request(.todos) { result in
            switch result {
            case .success(let data):
                print(data)

            case .failure(let error):
                print(error)
            }
        }
    }
}

```