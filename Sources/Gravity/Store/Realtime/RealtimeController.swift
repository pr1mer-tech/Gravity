//
//  RealtimeController.swift
//  
//
//  Created by Arthur Guiot on 08/04/2023.
//

import Foundation
import Network

public final class RealtimeController<Delegate> where Delegate: RemoteObjectDelegate {
    var subscriptions = Set<RemoteRequest<Delegate.Element.ID>>()
    var subscribed = Set<RemoteRequest<Delegate.Element.ID>>()
    
    var heartbeatTimer: Timer? = nil
    var heartbeatInterval: TimeInterval = 5
    
    let pathMonitor = NWPathMonitor()
    var isMonitoring = false
    
    var isConnected = false
    
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
        self.heartbeatTimer?.invalidate()
        self.heartbeatTimer = nil
        guard isMonitoring else { return }
        isMonitoring = false
        
        pathMonitor.cancel()
    }
    
    func networkChanged() {
        if pathMonitor.currentPath.status == .satisfied {
            Task { await self.connect() }
        } else {
            self.heartbeatTimer?.invalidate()
            self.heartbeatTimer = nil
        }
    }
    
    func connect(retryingAfter: TimeInterval = 0) async {
        let connect = await Delegate.shared.connect(heartbeat: false)
        guard connect != nil else { return }
        guard connect != .connecting else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task { await self.connect(retryingAfter: 0) }
            }
            return
        }
        if connect == .disconnected {
            print("Gravity: Connection failed")
            // Retry exponentially
            guard retryingAfter < 60 else { return } // Too many retries
            let retryingAfter = retryingAfter == 0 ? 1 : retryingAfter * 2
            DispatchQueue.main.asyncAfter(deadline: .now() + retryingAfter) {
                Task { await self.connect(retryingAfter: retryingAfter) }
            }
            return
        }
        self.isConnected = connect == .connected
        guard self.isConnected else { return }
        // Start heartbeat
        if self.heartbeatTimer == nil || !(self.heartbeatTimer?.isValid ?? false) {
            await MainActor.run {
                self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { _ in
                    Task { await self.heartbeat() }
                }
                self.heartbeatTimer?.tolerance = 1
            }
        }
        self.heartbeatTimer?.fire()
    }
    
    func heartbeat() async {
        let connect = await Delegate.shared.connect(heartbeat: true)
        guard connect != nil else { return }
        guard connect != .connecting else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task { await self.connect(retryingAfter: 0) }
            }
            return
        }
        if connect == .disconnected {
            print("Gravity: Heartbeat failed")
            // Unsubscribe from all
            self.subscriptions.forEach { self.subscribed.remove($0) }
            // Reconnect
            await self.connect()
        }
        self.isConnected = connect == .connected
        guard self.isConnected else { return }
        
        self.subscriptions.subtracting(self.subscribed).forEach { sub in
            // Ask delegate
            if Delegate.shared.subscribe(request: sub) {
                self.subscribed.insert(sub)
            }
        }
    }
    
    public func subscribe(to request: RemoteRequest<Delegate.Element.ID>) {
        guard !self.subscriptions.contains(request) else { return }
        self.subscriptions.insert(request)
    }
    
    public func unsubscribe(to request: RemoteRequest<Delegate.Element.ID>) {
        guard self.subscriptions.contains(request) else { return }
        Delegate.shared.unsubscribe(request: request)
        self.subscriptions.remove(request)
        self.subscribed.remove(request)
    }
}
