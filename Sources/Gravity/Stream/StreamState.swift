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

internal class StreamState<Value>: ObservableObject, WebSocketDelegate {
    let monitor = NWPathMonitor()
    
    var processor: Streamable<Value>? = nil
    
    @Published var object: StateResponse<URL, Value>? = nil
    
    var key: URL? = nil
    
    
    func connect(key: URL, processor: Streamable<Value>, data: Value? = nil) {
        self.processor = processor
        self.key = key

        object = StateResponse(key: key, data: data)
        
        var request = URLRequest(url: key)
        request.timeoutInterval = 5
        self.socket = WebSocket(request: request)
        self.socket?.delegate = self
        self.socket?.connect()
    }
    
    var socket: WebSocketClient? = nil

    func websocketDidConnect(socket: WebSocketClient) {
        self.socket = socket
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.socket = socket
        self.object?.error = error
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.socket = socket
        guard let data = text.data(using: .utf8) else { return }
        do {
            let value = try processor!.decode(message: data)
            self.object?.data = value
        } catch {
            self.object?.error = error
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        self.socket = socket
        do {
            let value = try processor!.decode(message: data)
            self.object?.data = value
        } catch {
            self.object?.error = error
        }
    }
}
