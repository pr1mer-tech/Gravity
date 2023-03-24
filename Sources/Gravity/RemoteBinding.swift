//
//  RemoteBinding.swift
//  
//
//  Created by Arthur Guiot on 24/03/2023.
//

import SwiftUI

@MainActor
@dynamicMemberLookup
public struct RemoteBinding<Delegate> where Delegate: RemoteObjectDelegate {
    var id: Delegate.Element.ID?
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Delegate.Element, T>) -> Binding<T>? {
        guard let id = id else { return nil }
        guard Delegate.shared.store.object(id: id) != nil else { return nil }
        return Binding<T> {
            return Delegate.shared.store.object(id: id)![keyPath: keyPath]
        } set: { newValue, transaction in
            try? Delegate.shared.store.update(id: id) { (object: inout Delegate.Element) in
                object[keyPath: keyPath] = newValue
            }
        }
    }
}

public extension Binding {
    func unwrap<T>(defaultValue: T) -> Binding<T>! where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
