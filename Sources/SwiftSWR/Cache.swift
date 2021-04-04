//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Combine
import Foundation


internal class Cache: ObservableObject {
    struct CacheValue<T> {
        var cachedResponse: StateResponse<T>
        let fetcher: Fetcher<T>
    }
    
    @Published var cache = [UUID: CacheValue<Any>]()
    
    static let shared = Cache()
    
    init(initialData: [UUID: CacheValue<Any>] = [:]) {
        cache = initialData
    }
    
    func get(key: UUID) -> StateResponse<Any>? {
        guard let entry = cache[key] else { return nil }
        let res = entry.cachedResponse
        return res
    }
    
    func set(key: UUID, value: CacheValue<Any>) {
        cache[key] = value
    }

    func set(key: UUID, value: StateResponse<Any>) {
        cache[key]?.cachedResponse = value
    }
    
    func revalidate(key: UUID) {
        guard let entry = cache[key] else { return }
        DispatchQueue.global().async {
            entry.fetcher { newValue in
                self.set(key: key, value: newValue)
            }
        }
    }
}
