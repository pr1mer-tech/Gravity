//
//  Store.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation

@MainActor
public class Store<Delegate>: ObservableObject where Delegate: RemoteObjectDelegate {
    typealias T = Delegate.Element
    
    let logger = Logger()
    
    let cache: Cache<Delegate.Element>
    
    var scheduler = Scheduler<Delegate>()
    
    var needPush = Set<T.ID>()
    var needPull = Set<RemoteRequest<T.ID>>()
    
    var subscriptions = Set<RemoteRequest<T.ID>>()

    public nonisolated init(reference: String,
                            entryLifetime: TimeInterval = 12 * 60 * 60,
                            maximumEntryCount: Int = 50) throws {
        self.cache = try Cache<Delegate.Element>(withReference: reference)
        self.cache.entryLifetime = entryLifetime
        self.cache.entryCache.countLimit = maximumEntryCount
    }
    
    func purgePush(_ pushed: Set<T.ID>) {
        self.needPush.subtract(pushed)
    }
    
    func purgePull(_ pulled: RemoteRequest<T.ID>) {
        self.needPull.remove(pulled)
    }
    
    func revalidate(request: RemoteRequest<T.ID>) {
        needPull.insert(request)
        try? self.scheduler.requestSync(delay: 0)
    }
    
    public func saveToDisk() throws {
        try self.cache.saveToDisk()
    }
    
    func save(_ element: T, with request: RemoteRequest<T.ID>, requestPushWithInterval interval: TimeInterval? = 5) throws {
        cache.insert(element, with: request)
        if let interval = interval {
            self.needPush.insert(element.id)
            try scheduler.requestSync(delay: interval)
        }
        // Notify all views that something has changed
        self.objectWillChange.send()
    }
    
    func save(elements: [T], with request: RemoteRequest<T.ID>, requestPushWithInterval interval: TimeInterval? = 5) throws {
        try elements.forEach { element in
            try save(element, with: request, requestPushWithInterval: interval)
        }
    }
    
    
    /// Adds element to the store, and updates all the views subscribed to the request, or displaying this element.
    /// - Parameters:
    ///   - element: Whatever element
    ///   - request: The request you're subscribing to
    public func add(_ element: Delegate.Element, with request: RemoteRequest<Delegate.Element.ID>, requestPushWithInterval interval: TimeInterval? = nil) throws {
        try save(element, with: request, requestPushWithInterval: interval)
    }
    
    /// Updates element in the store, and updates all the views subscribed to the request, or displaying this element.
    /// - Parameters:
    ///   - id: The id/key of the element you need to update.
    ///   - request: The request you're subscribing to
    ///   - update: The inout function to update the element.
    public func update(elementWithID id: Delegate.Element.ID, with request: RemoteRequest<Delegate.Element.ID>, requestPushWithInterval interval: TimeInterval? = nil, _ update: (inout Delegate.Element) -> Void) throws {
        guard var object = self.object(id: id) else { return }
        update(&object)
        try self.save(object, with: request, requestPushWithInterval: interval)
    }
    
    func update(id: T.ID, with request: RemoteRequest<T.ID>, _ update: (inout T) -> Void) throws {
        guard var object = self.object(id: id) else { return }
        update(&object)
        try self.save(object, with: request)
    }
    
    internal func object(id: T.ID) -> T? {
        cache.value(forKey: id)
    }
    
    func objects(request: RemoteRequest<T.ID>) -> [T] {
        guard let ids = request.isAll ? self.cache.allKeys : self.cache.keys(forRequest: request) else {
            self.revalidate(request: request)
            return []
        }
        let objects = ids.map { self.object(id: $0) }
        
        if objects.contains(nil) {
            self.revalidate(request: request)
        }
        return objects.compactMap { $0 }
    }
}

extension Store {
    func subscribe(to request: RemoteRequest<T.ID>) {
        guard !self.subscriptions.contains(request) else { return }
        // Ask delegate
        if Delegate.shared.subscribe(request: request) {
            self.subscriptions.insert(request)
        }
    }
    
    func unsubscribe(to request: RemoteRequest<T.ID>) {
        guard self.subscriptions.contains(request) else { return }
        Delegate.shared.unsubscribe(request: request)
    }
}
