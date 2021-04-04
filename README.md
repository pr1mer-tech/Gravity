# SwiftSWR


## Introduction

SwiftSWR is a SwiftUI library for remote data fetching.

The name “**SWR**” is derived from `stale-while-revalidate`, a cache invalidation strategy popularized by [HTTP RFC 5861](https://tools.ietf.org/html/rfc5861).
**SWR** first returns the data from cache (stale), then sends the fetch request (revalidate), and finally comes with the up-to-date data again.

With SWR, components will get **a stream of data updates constantly and automatically**. Thus, the UI will be always **fast** and **reactive**.

<br/>

## Quick Start

```swift
import SwiftUI
import SwiftSWR

struct LandmarkList: View {
    @SWR(url: "https://example.org/api/endpoint", model: Landmark) var api
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

The `url` is the URL of the API. And the `model` is a `Decodable` object.

`api` will be a `StateResponse` object that has three children: `data` that will contain the decoded data, `error` in case there is an error and `awaiting` when the app is loading.
