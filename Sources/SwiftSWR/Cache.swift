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
    weak var timer: Timer?
    
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
    
    func revalidate() {
        self.cache.fetcher { newValue in
            DispatchQueue.main.async {
                self.set(value: newValue)
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {_ in 
            self.revalidate()
        }
    }

    func stopTimer() {
        timer?.invalidate()
    }

    // if appropriate, make sure to stop your timer in `deinit`

    deinit {
        stopTimer()
    }
}
