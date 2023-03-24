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

public extension Binding {
    func unwrap<T>(defaultValue: T) -> Binding<T> where Value: OptionalProtocol, Value.Wrapped == T {
        if let wrappedValue = self.wrappedValue as? T {
            return Binding<T>(get: { wrappedValue }, set: { newValue in
                guard let newValue = newValue as? Value else { return }
                self.wrappedValue = newValue
            })
        } else {
            return (self.wrappedValue as? Binding)?.unwrap(defaultValue: defaultValue) ?? .constant(defaultValue)
        }
    }
}

public protocol OptionalProtocol {
    associatedtype Wrapped
    var wrappedValue: Wrapped? { get }
}

extension Optional: OptionalProtocol {
    public var wrappedValue: Wrapped? { return self }
}
