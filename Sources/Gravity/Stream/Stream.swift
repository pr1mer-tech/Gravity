//
//  Stream.swift
//  
//
//  Created by Arthur Guiot on 4/26/21.
//

import SwiftUI
import Starscream

@propertyWrapper
public struct GravityStream<Value> : DynamicProperty {
    let uri: URL
    let processor: Streamable<Value>
    
    class ContainerObject: ObservableObject {
        @Published var value: Value? = nil
        @Published var error: Error? = nil
    }
    @ObservedObject var container = ContainerObject()
    
    // Initialize with value
    public init(wrappedValue value: Value, url: String, processor: Streamable<Value>) {
        guard let uri = URL(string: url) else { fatalError("[Gravity Stream] Invalid URL: \(url)") }
        
        self.uri = uri
        self.processor = processor
        self.container.value = value
        
        self.connect()
    }
    // Initialize without value
    public init(url: String, processor: Streamable<Value>) {
        guard let uri = URL(string: url) else { fatalError("[Gravity Stream] Invalid URL: \(url)") }
        
        self.uri = uri
        self.processor = processor
        
        self.connect()
    }
    
    
    func connect() {
        StreamCache.shared.connect(key: self.uri)
        // Add listeners
        var hasher = Hasher()
        self.uri.hash(into: &hasher)
        let hash = hasher.finalize()
        
        StreamCache.shared.notification.addObserver(forName: .init(String(hash)), object: nil, queue: .main) { _ in
            // Update state
            self.updateState()
        }
        // Update state
        self.updateState()
    }
    
    public func updateState() {
        do {
            let connector = try StreamCache.shared.get(for: self.uri)
            self.container.error = connector.error
            
            guard let message = connector.data else { return }
            self.container.value = try processor.decode(message: message)
        } catch let err {
            self.container.error = err
        }
    }
    
    public var wrappedValue: StateResponse<URL, Value> {
        get {
            return StateResponse(key: self.uri, data: self.container.value, error: self.container.error)
        }
        nonmutating set {
            // Send request to WS server
            guard let connector = try? StreamCache.shared.get(for: self.uri) else { return }
            guard let object = newValue.data else { return }
            guard let message = try? processor.encode(value: object) else { return }
            connector.socket?.write(data: message)
        }
    }
}


public extension GravityStream where Value: Codable {
    /// JSON Decoder init
    init(wrappedValue value: Value, url: String) {
        self.init(wrappedValue: value, url: url, processor: JSONStreamProcessor<Value>())
    }
    /// JSON Decoder init
    init(url: String, options: SWROptions = .default) where Value: Codable {
        self.init(url: url, processor: JSONStreamProcessor<Value>())
    }
}
