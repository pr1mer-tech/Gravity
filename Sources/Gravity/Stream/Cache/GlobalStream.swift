//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/28/21.
//

import Foundation
import Combine
import Starscream
public class StreamCache {
    public static var shared = StreamCache()
    
    let notification = NotificationCenter()
    
    internal class Connector: WebSocketDelegate {
        let key: Int
        init(key: Int) {
            self.key = key
        }
        
        var socket: WebSocketClient? = nil
        
        var data: Data? = nil
        var error: Error? = nil
        
        func websocketDidConnect(socket: WebSocketClient) {
            self.socket = socket
        }
        
        func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
            self.socket = socket
            self.error = error
            StreamCache.shared.notification.post(name: .init(String(key)), object: nil, userInfo: nil)
        }
        
        func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
            self.socket = socket
            guard let data = text.data(using: .utf8) else { return }
            self.data = data
            StreamCache.shared.notification.post(name: .init(String(key)), object: nil, userInfo: nil)
        }
        
        func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
            self.socket = socket
            self.data = data
            StreamCache.shared.notification.post(name: .init(String(key)), object: nil, userInfo: nil)
        }
    }
    
    var connectors: [Int: Connector] = [:]

    func connect(key: URL) {
        // Hasher
        var hasher = Hasher()
        key.hash(into: &hasher)
        let hash = hasher.finalize()
        
        guard connectors[hash] == nil else { return }
        
        var request = URLRequest(url: key)
        request.timeoutInterval = 5
        let connector = Connector(key: hash)
        
        connector.socket = WebSocket(request: request)
        connector.socket?.delegate = connector
        connector.socket?.connect()
        
        connectors[hash] = connector
    }
    
    enum CacheError: Error {
        case invalidKey
    }
    
    /// Retrieve connector
    func get(for location: URL) throws -> Connector {
        // Hasher
        var hasher = Hasher()
        location.hash(into: &hasher)
        let key = hasher.finalize()
        
        guard let entry = connectors[key] else { throw CacheError.invalidKey }
        return entry
    }
}
