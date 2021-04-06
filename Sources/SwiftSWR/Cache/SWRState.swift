//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Combine
import Foundation
import Network

struct SWRStateObject<T> {
    var cachedResponse: StateResponse<T>
    let fetcher: Fetcher<T>
}

internal class SWRState<T>: ObservableObject {
    weak var timer: Timer?
    let monitor = NWPathMonitor()
    
    @Published var object: SWRStateObject<T>
    
    let identifier: Int
    
    init(id: Int, initialData: SWRStateObject<T>) {
        object = initialData
        identifier = id
        
        Cache.shared.notification.addObserver(forName: .init(String(id)), object: nil, queue: nil) { notification in
            guard let userInfos = notification.userInfo else { return }
            guard let makeRequest = userInfos["makeRequest"] as? Bool else { return }
            if makeRequest {
                self.revalidate()
            }
            
            guard let mutated = userInfos["mutated"] as? T else { return }
            self.object.cachedResponse.data = mutated
        }
    }
    
    var get: StateResponse<T> {
        return object.cachedResponse
    }
    
    func set(value: SWRStateObject<T>) {
        object = value
    }

    func set(value: StateResponse<T>) {
        object.cachedResponse = StateResponse(id: self.identifier, data: value.data, error: value.error)
    }
    
    func revalidate() {
        self.object.fetcher { newValue in
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
