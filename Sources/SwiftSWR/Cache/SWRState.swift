//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Combine
import Foundation
import Network

internal class SWRState<Key, Value>: ObservableObject where Key: Hashable {
    weak var timer: Timer?
    let monitor = NWPathMonitor()
    
    let fetcher: Fetcher<Key, Value>
    
    @Published var object: StateResponse<Key, Value>
    
    let key: Key
    
    init(key: Key, fetcher: Fetcher<Key, Value>, data: Value? = nil) {
        self.fetcher = fetcher
        self.key = key
        
        object = StateResponse(key: key, data: data)
        
        // Listener
        var hasher = Hasher()
        key.hash(into: &hasher)
        let id = hasher.finalize()
        Cache.shared.notification.addObserver(self, selector: #selector(mutate(_:)), name: .init(String(id)), object: nil)
    }
    
    var get: StateResponse<Key, Value> {
        return object
    }

    func set(data: Value?, error: Error? = nil) {
        object = StateResponse(key: key, data: data, error: error)
    }
    
    @objc func mutate(_ notification: Notification) {
        guard let userInfos = notification.userInfo else { return }
        guard let makeRequest = userInfos["makeRequest"] as? Bool else { return }
        if makeRequest {
            self.revalidate()
        }
        
        guard let mutated = userInfos["mutated"] as? Value else { return }
        DispatchQueue.main.async {
            self.set(data: mutated)
            // Encode and store to cache
            guard let data = try? self.fetcher.encode(object: mutated) else { return }
            Cache.shared.set(for: self.key, value: data)
        }
    }
    
    func revalidate(force: Bool = true) {
        if !force, let cached = try? Cache.shared.get(for: key) {
            do {
                let decoded = try fetcher.decode(data: cached)
                self.set(data: decoded)
            } catch {
                self.set(data: nil, error: error)
            }
            return
        }
        Cache.shared.request(from: key, using: fetcher) { (data, error) in
            DispatchQueue.main.async {
                do {
                    guard let data = data else {
                        self.set(data: nil, error: error)
                        return
                    }
                    let decoded = try self.fetcher.decode(data: data)
                    self.set(data: decoded, error: error)
                } catch {
                    self.set(data: nil, error: error)
                }
            }
        }
    }
    
    // MARK: Refresh
    func setupRefresh(_ options: SWROptions) {
        if options.contains(.autoRefresh) {
            startTimer(delay: 15)
        }
        
        // Just in case there was another queue
        guard monitor.pathUpdateHandler == nil else { return }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { path in
            if path.isExpensive {
                self.stopTimer()
            } else if options.contains(.autoRefresh) {
                self.startTimer(delay: 15)
            }
            if path.status == .satisfied && options.contains(.revalidateOnReconnect) {
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
        stopTimer();
        // Remove listener
        var hasher = Hasher()
        key.hash(into: &hasher)
        let id = hasher.finalize()
        Cache.shared.notification.removeObserver(self, name: .init(String(id)), object: nil)
    }
}
