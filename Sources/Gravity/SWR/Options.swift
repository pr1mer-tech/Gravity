//
//  Options.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import Foundation
/// Options for SWR property wrapper.
public struct SWROptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Auto Refresh data every 15 seconds
    ///
    /// In many cases, data changes because it's based on something happening in real time. SWR will refresh the data every 15 seconds to stay up to date.
    ///
    public static let autoRefresh = SWROptions(rawValue: 1 << 0)
    /// Revalidate data when the user is back online
    ///
    /// It's useful to also revalidate when the user is back online. This scenario happens a lot when the user unlocks their computer, but the internet is not yet connected at the same moment.
    ///
    /// To make sure the data is always up-to-date, SWR automatically revalidates when network recovers.
    ///
    public static let revalidateOnReconnect = SWROptions(rawValue: 1 << 1)
    
    /// When you re-focus the app or switch between tabs, SWR automatically revalidates data.
    public static let revalidateOnFocus = SWROptions(rawValue: 1 << 2)
    
    /// polling when the window is invisible (if `refreshInterval` is enabled)
    public static let refreshWhenHidden = SWROptions(rawValue: 1 << 3)
    /// polling when the user is offline
    public static let refreshWhenOffline = SWROptions(rawValue: 1 << 4)
    
    /// Default configuration
    public static let `default`: SWROptions = [.revalidateOnReconnect, .revalidateOnFocus]
}
