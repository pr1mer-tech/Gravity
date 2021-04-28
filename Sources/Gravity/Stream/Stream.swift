//
//  Stream.swift
//  
//
//  Created by Arthur Guiot on 4/26/21.
//

import SwiftUI
import Starscream

@propertyWrapper
@available(iOS 14.0, OSX 10.15, *)
public struct GravityStream<Value> : DynamicProperty {
    @StateObject var controller = StreamState<Value>()
    
    // Initialize with value
    public init(wrappedValue value: Value, url: String, processor: Streamable<Value>, options: SWROptions = .default) {
        guard let uri = URL(string: url) else { fatalError("[Gravity Stream] Invalid URL: \(url)") }
        
        if controller.key != nil {
            controller.connect(key: uri, processor: processor, data: value)
        }
    }
    // Initialize without value
    public init(url: String, processor: Streamable<Value>, options: SWROptions = .default) {
        guard let uri = URL(string: url) else { fatalError("[Gravity Stream] Invalid URL: \(url)") }
        
        if controller.key != nil {
            controller.connect(key: uri, processor: processor)
        }
    }
    
    public var wrappedValue: StateResponse<URL, Value> {
        get {
            return controller.object!
        }
        nonmutating set {
            controller.object = newValue
        }
    }
}

