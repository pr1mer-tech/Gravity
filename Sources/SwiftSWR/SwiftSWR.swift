import SwiftUI

@propertyWrapper
public struct SWR<Value> : DynamicProperty {
    @ObservedObject var cache: LocalCache<Value>
    // Initialize with value
    public init(wrappedValue value: Value, fetcher: @escaping Fetcher<Value>, options: SWROptions = .init()) {
        let row = LocalCacheValue<Value>(cachedResponse: StateResponse<Value>(data: value),
                                   fetcher: fetcher)
        
        cache = LocalCache(initialData: row)
        
        cache.revalidate()
        // Refresh
        cache.setupRefresh(options)
    }
    // Initialize without value
    public init(fetcher: @escaping Fetcher<Value>, options: SWROptions = .init()) {
        let row = LocalCacheValue<Value>(cachedResponse: StateResponse<Value>(),
                                   fetcher: fetcher)
        
        cache = LocalCache(initialData: row)
        
        cache.revalidate()
        // Refresh
        cache.setupRefresh(options)
    }
    
    public var wrappedValue: StateResponse<Value> {
        get {
            return cache.get
        }
        nonmutating set {
            cache.set(value: newValue)
        }
    }
}
/// Other inits
public extension SWR {
    /// JSON Decoder init
    init(wrappedValue value: Value, url: String, options: SWROptions = .init()) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(wrappedValue: value, fetcher: fetcher, options: options)
    }
    /// JSON Decoder init
    init(url: String, options: SWROptions = .init()) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(fetcher: fetcher, options: options)
    }
}
