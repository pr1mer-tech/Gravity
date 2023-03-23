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
    
    public subscript(dynamicMember string: String) -> Binding<Delegate.Element> {
        return Binding<Delegate.Element> {
            return Delegate.shared.store.object(id: id)!
        } set: { newValue, transaction in
            try? Delegate.shared.store.save(newValue)
        }
    }
}
