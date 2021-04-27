//
//  SWR.swift
//
//
//  Created by Arthur Guiot on 4/26/21.
//

import SwiftUI

@propertyWrapper
public struct SWR<Key, Value> : DynamicProperty where Key: Hashable {
    @ObservedObject var controller: SWRState<Key, Value>
    
    // Initialize with value
    public init(wrappedValue value: Value, key: Key, fetcher: Fetcher<Key, Value>, options: SWROptions = .default) {
        controller = SWRState(key: key, fetcher: fetcher, data: value)
        
        controller.revalidate(force: false)
        // Refresh
        controller.setupRefresh(options)
    }
    // Initialize without value
    public init(key: Key, fetcher: Fetcher<Key, Value>, options: SWROptions = .default) {
        controller = SWRState(key: key, fetcher: fetcher)
        
        controller.revalidate(force: false)
        // Refresh
        controller.setupRefresh(options)
    }
    
    public var wrappedValue: StateResponse<Key, Value> {
        get {
            return controller.get
        }
        nonmutating set {
            controller.set(data: newValue.data, error: newValue.error)
        }
    }
}
/// Other inits
public extension SWR where Key == URL {
    /// JSON Decoder init
    init(wrappedValue value: Value, url: String, options: SWROptions = .default) where Value: Codable {
        guard let uri = URL(string: url) else { fatalError("[Gravity SWR] Invalid URL: \(url)") }
        self.init(wrappedValue: value, key: uri, fetcher: FetcherDecodeJSON(), options: options)
    }
    /// JSON Decoder init
    init(url: String, options: SWROptions = .default) where Value: Codable {
        guard let uri = URL(string: url) else { fatalError("[Gravity SWR] Invalid URL: \(url)") }
        self.init(key: uri, fetcher: FetcherDecodeJSON(), options: options)
    }
}
