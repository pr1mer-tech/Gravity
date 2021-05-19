//
//  StateResponse.swift
//  
//
//  Created by Arthur Guiot on 4/27/21.
//

import SwiftUI
/// The returned object for Gravity Stream or SWR property wrappers.
public class StateResponse<Key, Value>: ObservableObject where Key: Hashable {
    public var awaiting: Bool {
        return data == nil
    }
    
    @Published public var error: Error? = nil
    @Published public var data: Value? = nil
    
    internal let identifier: Key
    
    /// Create StateResponse
    init(key: Key, data: Value? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
        self.identifier = key
    }
}
