import SwiftUI

@propertyWrapper
public struct SWR<Value> : DynamicProperty {
    internal let id = UUID()
    @ObservedObject var cache: Cache<Value>
    
    public init(wrapperValue value: Value, fetcher: @escaping Fetcher<Value>) {
        let row = CacheValue<Value>(cachedResponse: StateResponse<Value>(data: value),
                                   fetcher: fetcher)
        
        cache = Cache(initialData: row)
        
        cache.revalidate(key: id)
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


public extension SWR where Value: ExpressibleByNilLiteral {
    init(fetcher: @escaping Fetcher<Value>) {
        self.init(wrapperValue: nil, fetcher: fetcher)
    }
}
