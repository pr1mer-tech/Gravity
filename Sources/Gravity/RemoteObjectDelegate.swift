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
    func subscribe(request: RemoteRequest<Element.ID>) -> Bool
    func unsubscribe(request: RemoteRequest<Element.ID>)
}

public extension RemoteObjectDelegate {
    func subscribe(request: RemoteRequest<Element.ID>) -> Bool {
        return false
    }
    func unsubscribe(request: RemoteRequest<Element.ID>) {}
}

internal extension RemoteObjectDelegate {
    
    func sync() async throws {
        let needPush = await self.store.needPush
        let needPull = await self.store.needPull
        
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
    
    func requestPull(needPull: Set<RemoteRequest<Element.ID>>) async throws {
        for pull in needPull {
            let results = try await self.pull(request: pull)
            try await self.store.save(elements: results, with: pull, requestPush: false)
            // Remove from needPull
            await self.store.purgePull(pull)
        }
    }
}
