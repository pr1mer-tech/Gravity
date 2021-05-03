//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/27/21.
//

import Combine
import Foundation
import Network
import Starscream

internal class StreamState<Value>: ObservableObject {
    let monitor = NWPathMonitor()
    
    var processor: Streamable<Value>? = nil
    
    @Published var object: StateResponse<URL, Value>? = nil
    
    var key: URL? = nil
    
    
    func connect(key: URL, processor: Streamable<Value>, data: Value? = nil) {
        self.processor = processor
        self.key = key

        object = StateResponse(key: key, data: data)
        
        StreamCache.shared.connect(key: key)
        // Add listeners
        var hasher = Hasher()
        key.hash(into: &hasher)
        let hash = hasher.finalize()
        
        StreamCache.shared.notification.addObserver(self, selector: #selector(update(_:)), name: .init(String(hash)), object: nil)
    }
    
    @objc func update(_ notification: Notification) {
        guard let userInfos = notification.userInfo as? [String: Any] else { return }
        if let data = userInfos["data"] as? Data {
            guard let processor = self.processor else { return }
            do {
                let value = try processor.decode(message: data)
                object?.data = value
                object?.error = nil
            } catch {
                object?.error = error
            }
        }
        if let error = userInfos["error"] as? Error {
            object?.error = error
        }
    }
}
