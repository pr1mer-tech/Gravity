//
//  RealtimeController.swift
//  
//
//  Created by Arthur Guiot on 08/04/2023.
//

import Foundation
import Network

final class RealtimeController<Delegate> where Delegate: RemoteObjectDelegate {
    var subscriptions = Set<RemoteRequest<Delegate.Element.ID>>()
    
    var heartbeatTimer: Timer?
    var heartbeatInterval: TimeInterval = 30
    
    let pathMonitor = NWPathMonitor()
    var isMonitoring = false
    
    init() {
        self.startMonitoring()
        Task { await self.connect() }
    }

    deinit {
        self.stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkChanged()
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        pathMonitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        pathMonitor.cancel()
    }
    
    func networkChanged() {
        if pathMonitor.currentPath.status == .satisfied {
            Task { await self.connect() }
        } else {
            self.heartbeatTimer?.invalidate()
        }
    }
    
    func connect(retryingAfter: TimeInterval = 0) async {
        if await !Delegate.shared.connect(heartbeat: false) {
            print("Gravity: Connection failed")
            // Retry exponentially
            guard retryingAfter < 60 else { return } // Too many retries
            let retryingAfter = retryingAfter == 0 ? 1 : retryingAfter * 2
            DispatchQueue.main.asyncAfter(deadline: .now() + retryingAfter) {
                Task { await self.connect(retryingAfter: retryingAfter) }
            }
            return
        }
        // Start heartbeat
        if self.heartbeatTimer != nil {
            self.heartbeatTimer?.invalidate()
        }
        self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { _ in
            Task { await self.heartbeat() }
        }
    }
    
    func heartbeat() async {
        if await !Delegate.shared.connect(heartbeat: true) {
            print("Gravity: Heartbeat failed")
            // Unsubscribe from all
            self.subscriptions.forEach { self.unsubscribe(to: $0) }
            // Reconnect
            await self.connect()
        }
    }
    
    func subscribe(to request: RemoteRequest<Delegate.Element.ID>) {
        guard !self.subscriptions.contains(request) else { return }
        // Ask delegate
        if Delegate.shared.subscribe(request: request) {
            self.subscriptions.insert(request)
        }
    }
    
    func unsubscribe(to request: RemoteRequest<Delegate.Element.ID>) {
        guard self.subscriptions.contains(request) else { return }
        Delegate.shared.unsubscribe(request: request)
    }
}
