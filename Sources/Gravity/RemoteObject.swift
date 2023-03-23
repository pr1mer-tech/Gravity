//
//  RemoteObject.swift
//  
//
//  Created by Arthur Guiot on 21/03/2023.
//

import SwiftUI

@propertyWrapper
public struct RemoteObject<Delegate> : DynamicProperty where Delegate: RemoteObjectDelegate {
    
    @ObservedObject var store: Store<Delegate>
    
    var id: Delegate.Element.ID!
    
    public init(id: Delegate.Element.ID) {
        self.store = Delegate.shared.store
        self.id = id
        self.store.revalidate(ids: [id])
    }
    
    public init(waitForId: Bool) {
        self.store = Delegate.shared.store
    }
    
    public mutating func updateId(id: Delegate.Element.ID) {
        self.id = id
        self.store.revalidate(ids: [id])
    }
    
    public func revalidate() {
        self.store.revalidate(ids: [id])
    }
    
    public var wrappedValue: Delegate.Element? {
        get {
            return store.object(id: id)
        }
        nonmutating set {
            guard let newValue = newValue else { return }
            do {
                try store.save(newValue)
            } catch {
                print("### Save to \(Delegate.Element.self) Store Error: \(error)")
            }
        }
    }
    
    public var projectedValue: Binding<Delegate.Element> {
        return .init(get: { self.wrappedValue! }, set: { self.wrappedValue = $0 })
    }
}
