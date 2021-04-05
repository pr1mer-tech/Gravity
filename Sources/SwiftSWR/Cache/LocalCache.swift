//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Combine
import Foundation
import Network

struct LocalCacheValue<T> {
    var cachedResponse: StateResponse<T>
    let fetcher: Fetcher<T>
}

internal class LocalCache<T>: ObservableObject {
    weak var timer: Timer?
    let monitor = NWPathMonitor()
    
    @Published var cache: LocalCacheValue<T>
    
    init(initialData: LocalCacheValue<T>) {
        cache = initialData
    }
    
    var get: StateResponse<T> {
        return cache.cachedResponse
    }
    
    func set(value: LocalCacheValue<T>) {
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
    
    // MARK: Refresh
    func setupRefresh(_ options: SWROptions) {
        startTimer(delay: options.refreshInterval)
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { path in
            if path.isExpensive {
                self.stopTimer()
            } else {
                self.startTimer(delay: options.refreshInterval)
            }
            if path.status == .satisfied && options.revalidateOnReconnect {
                self.revalidate()
            }
        }
    }
    
    func startTimer(delay: TimeInterval = 15) {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        guard delay > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true) {_ in
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
