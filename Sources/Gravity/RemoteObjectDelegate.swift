//
//  File.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation

public protocol RemoteObjectDelegate<Element> {
    associatedtype Element: Codable, Identifiable
    static var shared: Self { get }
    
    var store: Store<Self> { get } // Where the DB data will be stored
    
    // No reactivity
    func pull(ids: [Element.ID]) async throws -> [Element]
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
        let needPull = await self.store.needPull.subtracting(needPush)
        
        if !needPush.isEmpty {
            try await requestPush(needPush: needPush)
        }
        
        try await requestPull(needPull: needPull)
    }
    
    func requestPush(needPush: Set<Element.ID>) async throws {
        let objects = await self.store.objects(ids: Array(needPush))
        guard objects.count > 0 else { return }
        try await self.push(elements: objects)
        // Remove from needPush
        await self.store.purgePush(needPush)
    }
    
    func requestPull(needPull: Set<Element.ID>) async throws {
        let results = try await self.pull(ids: Array(needPull))
        try await self.store.save(elements: results, requestPush: false)
        // Remove from needPull
        await self.store.purgePull(needPull)
    }
}
