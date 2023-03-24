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
    
    var needPush = RemoteRequest<T.ID>.ids([])
    var needPull = RemoteRequest<T.ID>.ids([])

    public nonisolated init(reference: String,
                            entryLifetime: TimeInterval = 12 * 60 * 60,
                            maximumEntryCount: Int = 50) throws {
        self.cache = try Cache<Delegate.Element>(withReference: reference)
        self.cache.entryLifetime = entryLifetime
        self.cache.entryCache.countLimit = maximumEntryCount
    }
    
    func purgePush(_ pushed: RemoteRequest<T.ID>) {
        self.needPush -= pushed
    }
    
    func purgePull(_ pulled: RemoteRequest<T.ID>) {
        self.needPull -= pulled
    }
    
    func revalidate(request: RemoteRequest<T.ID>) {
        needPull += request
        try? self.scheduler.requestSync(delay: 0)
    }
    
    public func saveToDisk() throws {
        try self.cache.saveToDisk()
    }
    
    func save(_ element: T, with request: RemoteRequest<T.ID>? = nil, requestPush: Bool = true) throws {
        cache.insert(element, with: request)
        if requestPush {
            self.needPush += .id(element.id)
            try scheduler.requestSync()
        }
        // Notify all views that something has changed
        self.objectWillChange.send()
    }
    
    func save(elements: [T], with request: RemoteRequest<T.ID>? = nil, requestPush: Bool = true) throws {
        try elements.forEach { element in
            try save(element, with: request, requestPush: requestPush)
        }
    }
    
    func update(id: T.ID, _ update: (inout T) -> Void) throws {
        guard var object = self.object(id: id) else { return }
        update(&object)
        try self.save(object)
    }
    
    internal func object(id: T.ID) -> T? {
        cache.value(forKey: id)
    }
    
    func objects(request: RemoteRequest<T.ID>) -> [T] {
        guard let ids = request.isAll ? self.cache.allKeys : self.cache.keys(forRequest: request) else {
            self.revalidate(request: request)
            return []
        }
        let objects = ids.compactMap { id in
            let row = object(id: id)
            if row == nil {
                needPull += .id(id)
            }
            return row
        }
        if !self.needPull.isEmpty {
            self.revalidate(request: .ids([]))
        }
        return objects
    }
}
