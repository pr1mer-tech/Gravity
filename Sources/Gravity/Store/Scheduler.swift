//
//  RateLimiter.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation

class Scheduler<Delegate> where Delegate: RemoteObjectDelegate {
    var task: Task<Void, Error>? = nil
    
    func requestSync(delay: TimeInterval = 0) async throws {
        guard task == nil else { return }
        self.task = Task {
            // Sleep for N second
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            // Sync
            try await Delegate.shared.sync()
        }
        let result = await self.task?.result
        self.task = nil
        if case .failure(let error) = result {
            throw error
        }
    }
}
