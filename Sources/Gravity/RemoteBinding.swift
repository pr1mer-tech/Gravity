//
//  RemoteBinding.swift
//  
//
//  Created by Arthur Guiot on 22/03/2023.
//

import SwiftUI

@MainActor
@dynamicMemberLookup
public struct RemoteBinding<Delegate> where Delegate: RemoteObjectDelegate {
    
    var id: Delegate.Element.ID
    
    public func revalidate() {
        Delegate.shared.store.revalidate(ids: [id])
    }
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Delegate.Element, T>) -> Binding<T> {
        return Binding<T> {
            return Delegate.shared.store.object(id: id)![keyPath: keyPath]
        } set: { newValue, transaction in
            try? Delegate.shared.store.update(id: id) { (object: inout Delegate.Element) in
                object[keyPath: keyPath] = newValue
            }
        }
    }
}
