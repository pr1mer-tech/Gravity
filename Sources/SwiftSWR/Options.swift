//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Foundation

public struct SWROptions {
    public init(refreshInterval: TimeInterval = 0, revalidateOnReconnect: Bool = true) {
        self.refreshInterval = refreshInterval
        self.revalidateOnReconnect = revalidateOnReconnect
    }
    
    /// In many cases, data changes because it's based on something happening in real time. SWR lets you define a refreshing interval. If it's 0, it will be disabled.
    public var refreshInterval: TimeInterval = 0
    public var revalidateOnReconnect: Bool = true
}
