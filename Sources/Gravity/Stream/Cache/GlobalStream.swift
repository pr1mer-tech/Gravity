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
        init(onMessage: @escaping (Data) -> Void, onError: @escaping (Error?) -> Void) {
            self.onMessage = onMessage
            self.onError = onError
        }
        
        var socket: WebSocketClient? = nil

        var onMessage: (Data) -> Void
        var onError: (Error?) -> Void
        
        func websocketDidConnect(socket: WebSocketClient) {
            self.socket = socket
        }
        
        func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
            self.socket = socket
            onError(error)
        }
        
        func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
            self.socket = socket
            guard let data = text.data(using: .utf8) else { return }
            onMessage(data)
        }
        
        func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
            self.socket = socket
            onMessage(data)
        }
    }
    
    var cache: [Int: Connector] = [:]

    
    func connect(key: URL) {
        // Hasher
        var hasher = Hasher()
        key.hash(into: &hasher)
        let hash = hasher.finalize()
        
        guard cache[hash] == nil else { return }
        
        var request = URLRequest(url: key)
        request.timeoutInterval = 5
        let connector = Connector(onMessage: { (data) in
            self.notification.post(name: .init(String(hash)),
                                   object: nil,
                                   userInfo: [
                                    "data": data
                                   ]
            )
        }, onError: { (error) in
            self.notification.post(name: .init(String(hash)),
                                   object: nil,
                                   userInfo: [
                                    "error": error ?? GravityError.FetchError
                                   ]
            )
        })
        
        connector.socket = WebSocket(request: request)
        connector.socket?.delegate = connector
        connector.socket?.connect()
        
        cache[hash] = connector
    }
}
