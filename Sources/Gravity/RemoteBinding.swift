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
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Delegate.Element, T>) -> Binding<T?> {
        return Binding<T?> {
            guard let id = id else { return nil }
            return Delegate.shared.store.object(id: id)?[keyPath: keyPath]
        } set: { newValue, transaction in
            guard let newValue = newValue else { return }
            guard let id = id else { return }
            try? Delegate.shared.store.update(id: id) { (object: inout Delegate.Element) in
                object[keyPath: keyPath] = newValue
            }
        }
    }
}
