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
    var needPull = Set<T.ID>()

    public nonisolated init(reference: String) throws {
        self.cache = try Cache<Delegate.Element>(reference: reference)
    }
    
    func purgePush(_ pushed: Set<T.ID>) {
        self.needPush = self.needPush.subtracting(pushed)
    }
    
    func purgePull(_ pulled: Set<T.ID>) {
        self.needPull = self.needPull.subtracting(pulled)
    }
    
    func revalidate(ids: [T.ID] = []) {
        needPull.formUnion(ids)
        guard !needPull.isEmpty else { return }
        try? self.scheduler.requestSync(delay: 0)
    }
    
    public func saveToDisk() throws {
        try self.cache.saveToDisk()
    }
    
    func save(_ element: T, requestPush: Bool = true) throws {
        cache.insert(element)
        if requestPush {
            self.needPush.insert(element.id)
            try scheduler.requestSync()
        }
        // Notify all views that something has changed
        self.objectWillChange.send()
    }
    
    func save(elements: [T], requestPush: Bool = true) throws {
        try elements.forEach { element in
            try save(element, requestPush: requestPush)
        }
    }
    
    func object(id: T.ID) -> T? {
        cache.value(forKey: id)
    }
    
    func objects(ids: [T.ID] = []) -> [T] {
        let objects = ids.compactMap { id in
            let row = object(id: id)
            if row == nil {
                needPull.insert(id)
            }
            return row
        }
        self.revalidate()
        return objects
    }
}
