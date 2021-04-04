//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import SwiftUI

@available(OSX 10.15, *)
public class StateResponse<Value>: ObservableObject {
    var awaiting: Bool {
        return data == nil
    }
    
    @Published var error: Error? = nil
    @Published var data: Value? = nil
    /// Default init
    init() {}
    /// Create StateResponse with an error
    init(error: Error?) {
        self.error = error
    }
    /// Create StateResponse with an error
    init(data: Value?) {
        self.data = data
    }
    /// Create StateResponse
    init(data: Value?, error: Error?) {
        self.data = data
        self.error = error
    }
}

enum SWRError: LocalizedError {
    /// SWR couldn't retreive data from cache
    case CacheError
}
