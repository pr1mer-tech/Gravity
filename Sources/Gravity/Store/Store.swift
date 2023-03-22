//
//  Store.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import Foundation
import Stores

@MainActor
public class Store<Delegate>: ObservableObject where Delegate: RemoteObjectDelegate {
    typealias T = Delegate.Element
    
    var coreDataStore: AnyMultiObjectStore<T>
    
    nonisolated required init(reference: String) {
        self.coreDataStore = MultiCoreDataStore<Delegate.Element>(databaseName: reference).eraseToAnyStore()
    }
    
    var scheduler = Scheduler<Delegate>()
    
    var needPush = Set<T.ID>()
    var needPull = Set<T.ID>()
    
    func purgePush(_ pushed: Set<T.ID>) {
        self.needPush = self.needPush.subtracting(pushed)
    }
    
    func purgePull(_ pulled: Set<T.ID>) {
        self.needPull = self.needPull.subtracting(pulled)
    }
    
    func save(_ element: T, requestPush: Bool = true) throws {
        try self.coreDataStore.save(element)
        if requestPush {
            self.needPush.insert(element.id)
        }
        // Notify all views that something has changed
        self.objectWillChange.send()
    }
    
    func save(elements: [T], requestPush: Bool = true) throws {
        try elements.forEach { element in
            try self.save(element, requestPush: requestPush)
        }
    }
    
    func object(id: T.ID) -> T? {
        return self.coreDataStore.object(withId: id)
    }
    
    func objects(ids: [T.ID] = []) -> [T] {
        if ids.count > 0 {
            return self.coreDataStore.objects(withIds: ids)
        }
        return self.coreDataStore.allObjects()
    }
}
