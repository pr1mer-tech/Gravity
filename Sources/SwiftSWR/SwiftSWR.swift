import SwiftUI

@available(iOS 13.0, macOS 11, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct SWR<Value> : DynamicProperty {
    let id = UUID()
    @ObservedObject var cache = Cache.shared
    
    init(wrapperValue value: Value, fetcher: @escaping Fetcher<Value>) {
        let row = Cache.CacheValue<Value>(cachedResponse: StateResponse<Value>(data: value),
                                   fetcher: fetcher)
        
        cache.set(key: id, value: row as! Cache.CacheValue<Any>)
        cache.revalidate(key: id)
    }

    public var wrappedValue: StateResponse<Value> {
        get {
            guard let res = cache.get(key: id) else {
                return StateResponse<Value>(error: SWRError.CacheError)
            }
            return res as! StateResponse<Value>
        }
    }
}
