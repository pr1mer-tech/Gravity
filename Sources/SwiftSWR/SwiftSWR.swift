import SwiftUI

@propertyWrapper
public struct SWR<Value> : DynamicProperty {
    @ObservedObject var controller: SWRState<Value>
    /// Unique identifier for this SWR request.
    ///
    /// SWR requests with the same URL or Hashable key, will end up with the same identifier
    ///
    public var identifier: Int
    
    // Initialize with value
    public init<T>(wrappedValue value: Value, key: T, fetcher: @escaping Fetcher<Value>, options: SWROptions = .init()) where T: Hashable {
        // Hasher
        var hasher = Hasher()
        key.hash(into: &hasher)
        self.identifier = hasher.finalize()
        
        let row = SWRStateObject<Value>(cachedResponse: StateResponse<Value>(id: self.identifier, data: value),
                                   fetcher: fetcher)
        
        controller = SWRState(id: self.identifier, initialData: row)
        
        controller.revalidate(force: false)
        // Refresh
        controller.setupRefresh(options)
    }
    // Initialize without value
    public init<T>(key: T, fetcher: @escaping Fetcher<Value>, options: SWROptions = .init()) where T: Hashable {
        // Hasher
        var hasher = Hasher()
        key.hash(into: &hasher)
        self.identifier = hasher.finalize()
        
        let row = SWRStateObject<Value>(cachedResponse: StateResponse<Value>(id: self.identifier),
                                   fetcher: fetcher)
        
        controller = SWRState(id: self.identifier, initialData: row)
        
        controller.revalidate(force: false)
        // Refresh
        controller.setupRefresh(options)
    }
    
    public var wrappedValue: StateResponse<Value> {
        get {
            return controller.get
        }
        nonmutating set {
            controller.set(value: newValue)
        }
    }
}
/// Other inits
public extension SWR {
    /// JSON Decoder init
    init(wrappedValue value: Value, url: String, options: SWROptions = .init()) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(wrappedValue: value, key: url, fetcher: fetcher, options: options)
    }
    /// JSON Decoder init
    init(url: String, options: SWROptions = .init()) where Value: Decodable {
        guard let uri = URL(string: url) else { fatalError("[SwiftSWR] Invalid URL: \(url)") }
        let fetcher = FetcherDecodeJSON(url: uri, type: Value.self)
        self.init(key: url, fetcher: fetcher, options: options)
    }
}
