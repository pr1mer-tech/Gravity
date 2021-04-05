import SwiftUI

@propertyWrapper
public struct SWR<Value> : DynamicProperty {
    @ObservedObject var cache: Cache<Value>
    
    public init(wrapperValue value: Value?, fetcher: @escaping Fetcher<Value>, options: SWROptions = .default) {
        let row = CacheValue<Value>(cachedResponse: StateResponse<Value>(data: value),
                                   fetcher: fetcher)
        
        cache = Cache(initialData: row)
        
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


public extension SWR {
    /// Public init
    init(fetcher: @escaping Fetcher<Value>) {
        self.init(wrapperValue: nil, fetcher: fetcher)
    }
    
    /// JSON Decoder init
    init(url: String) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(fetcher: fetcher)
    }
    /// JSON Decoder init
    init(wrapperValue value: Value?, url: String) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(wrapperValue: value, fetcher: fetcher)
    }
}
