<p align="center">
    <img src="https://gravity.pr1mer.tech/logo.svg" width={150} height={150} /> 
    <h1 align="center">Gravity</h1>
</p>


## Introduction

Gravity is a SwiftUI library for remote data fetching. It uses **SWR** technonology to fetch data from the server.

The name “**SWR**” is derived from `stale-while-revalidate`, a cache invalidation strategy popularized by [HTTP RFC 5861](https://tools.ietf.org/html/rfc5861).
Gravity first returns the data from cache (stale), then sends the fetch request (revalidate), and finally comes with the up-to-date data again.

With Gravity, components will get **a stream of data updates constantly and automatically**. Thus, the UI will be always **fast** and **reactive**.

<br/>

## Quick Start

#### Installation

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

It is the recommended way to install Gravity.

Once you have your Swift package set up, adding Gravity as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/pr1mer-tech/Gravity.git", .upToNextMajor(from: "0.1.0"))
]
```
You can then import and use Gravity:
```swift
import SwiftUI
import Gravity

struct LandmarkList: View {
    @SWR<URL, Landmark>(url: "https://example.org/api/endpoint") var api
    var body: some View {
        if let landmarks = api.data {
            List(landmarks, id: \.id) { landmark in
                LandmarkRow(landmark: landmark)
            }
        }
    }
}
```

In this example, the property wrapper `@SWR` accepts a `url` and a `model`.

The `url` is the URL of the API. And the `model` is a `Codable` object.

`api` will be a `StateResponse` object that has three children: `data` that will contain the decoded data, `error` in case there is an error and `awaiting` when the app is loading.
