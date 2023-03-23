//
//  RateLimiter.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation

class Scheduler<Delegate> where Delegate: RemoteObjectDelegate {
    var task: Task<Void, Error>? = nil
    
    func requestSync(delay: TimeInterval = 5) throws {
        guard task == nil else { return }
        self.task = Task {
            // Sleep for N second
            try await Task.sleep(nanoseconds: UInt64(max(delay, 0.1) * 1_000_000_000)) // 0.1s to let view appear
            // Sync
            try await Delegate.shared.sync()
        }
        Task {
            let result = await self.task?.result
            self.task = nil
            if case .failure(let error) = result {
                throw error
            }
        }
    }
}
