//
//  RemoteObjects.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import SwiftUI

@propertyWrapper
public struct RemoteObjects<Delegate> : DynamicProperty where Delegate: RemoteObjectDelegate {
    
    @ObservedObject var store: Store<Delegate>
    
    var ids: [Delegate.Element.ID]
    
    public init(ids: [Delegate.Element.ID] = []) {
        self.store = Delegate.shared.store
        self.ids = ids
        
        self.store.revalidate(ids: ids)
    }
    
    public var wrappedValue: [Delegate.Element] {
        get {
            return store.objects(ids: ids)
        }
        nonmutating set {
            do {
                try store.save(elements: newValue)
            } catch {
                print("### Save to \(Delegate.Element.self) Store Error: \(error)")
            }
        }
    }
    
    public var projectedValue: Binding<[Delegate.Element]> {
        return .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
}
