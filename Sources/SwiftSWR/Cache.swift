//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Combine
import Foundation

struct CacheValue<T> {
    var cachedResponse: StateResponse<T>
    let fetcher: Fetcher<T>
}

internal class Cache<T>: ObservableObject {
    @Published var cache: CacheValue<T>
    
    init(initialData: CacheValue<T>) {
        cache = initialData
    }
    
    var get: StateResponse<T> {
        return cache.cachedResponse
    }
    
    func set(value: CacheValue<T>) {
        cache = value
    }

    func set(value: StateResponse<T>) {
        cache.cachedResponse = value
    }
    
    func revalidate(key: UUID) {
        DispatchQueue.global().async {
            self.cache.fetcher { newValue in
                self.set(value: newValue)
            }
        }
    }
}
