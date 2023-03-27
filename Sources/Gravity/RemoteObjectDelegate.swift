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
    
    // Data processing
    func process(elements: [Element], for request: RemoteRequest<Element.ID>) -> [Element]
    
    // CRUD
    func pull(request: RemoteRequest<Element.ID>) async throws -> [Element]
    func push(elements: [Element]) async throws
    func pop(elements: [Element]) async throws
    
    // Reactivity
    func subscribe(request: RemoteRequest<Element.ID>) -> Bool
    func unsubscribe(request: RemoteRequest<Element.ID>)
}

public extension RemoteObjectDelegate {
    func process(elements: [Element], for request: RemoteRequest<Element.ID>) -> [Element] {
        return elements
    }
    
    func pop(elements: [Element]) async throws {
        fatalError("Not Implemented")
    }
    
    func subscribe(request: RemoteRequest<Element.ID>) -> Bool {
        return false
    }
    func unsubscribe(request: RemoteRequest<Element.ID>) {}
}

internal extension RemoteObjectDelegate {
    
    func sync() async throws {
        let needPush = await self.store.needPush
        let needPull = await self.store.needPull
        let needPop  = await self.store.needPop
        
        if !needPush.isEmpty {
            try await requestPush(needPush: needPush)
        }
        
        if !needPop.isEmpty {
            try await requestPop(needPop: needPop)
        }
        
        if !needPull.isEmpty {
            try await requestPull(needPull: needPull)
        }
        
        // Time to save to disk
        try await self.store.saveToDisk()
    }
    
    func requestPush(needPush: Set<Element.ID>) async throws {
        let objects = try await needPush.compactAsyncMap { await self.store.object(id: $0) }
        guard objects.count > 0 else { return }
        try await self.push(elements: objects)
        // Remove from needPush
        await self.store.purgePush(needPush)
    }
    
    func requestPull(needPull: Set<RemoteRequest<Element.ID>>) async throws {
        for pull in needPull {
            let results = try await self.pull(request: pull)
            try await self.store.save(elements: results, with: pull, requestPushWithInterval: nil)
            // Remove from needPull
            await self.store.purgePull(pull)
        }
    }
    
    func requestPop(needPop: Set<Element>) async throws {
        try await self.pop(elements: Array(needPop))
        // Remove from needPop
        await self.store.purgePop(needPop)
    }
}

internal extension Sequence {
    func compactAsyncMap<T>(
        _ transform: @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        let results = try await tasks.asyncMap { task in
            try await task.value
        }
        
        return results.compactMap { $0 }
    }
    
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
}
