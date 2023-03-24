//
//  File.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation

public protocol RemoteRepresentable: Codable, Hashable, Identifiable where ID: Codable & Hashable {}

public protocol RemoteObjectDelegate<Element> {
    associatedtype Element: RemoteRepresentable
    static var shared: Self { get }
    
    var store: Store<Self> { get } // Where the DB data will be stored
    
    // No reactivity
    func pull(request: RemoteRequest<Element.ID>) async throws -> [Element]
    func push(elements: [Element]) async throws
    
    // Reactivity
    func subscribe()
    func unsubscribe()
}

public extension RemoteObjectDelegate {
    func pull() async throws -> [Element] {
        fatalError("Not Implemented")
    }
    
    func subscribe() {}
    func unsubscribe() {}
}

internal extension RemoteObjectDelegate {
    
    func sync() async throws {
        let needPush = await self.store.needPush
        let needPull = await self.store.needPull - needPush
        
        if !needPush.isEmpty {
            try await requestPush(needPush: needPush)
        }
        
        if !needPull.isEmpty {
            try await requestPull(needPull: needPull)
        }
    }
    
    func requestPush(needPush: RemoteRequest<Element.ID>) async throws {
        let objects = await self.store.objects(request: needPush)
        guard objects.count > 0 else { return }
        try await self.push(elements: objects)
        // Remove from needPush
        await self.store.purgePush(needPush)
    }
    
    func requestPull(needPull: RemoteRequest<Element.ID>) async throws {
        let results = try await self.pull(request: needPull)
        try await self.store.save(elements: results, with: needPull, requestPush: false)
        // Remove from needPull
        await self.store.purgePull(needPull)
    }
}
