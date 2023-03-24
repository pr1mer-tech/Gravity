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
    
    var request: RemoteRequest<Delegate.Element.ID>!
    
    public init(request: RemoteRequest<Delegate.Element.ID>) {
        self.store = Delegate.shared.store
        self.request = request
//        self.store.revalidate(request: request)
    }
    
    public init(waitForRequest: Bool) {
        self.store = Delegate.shared.store
    }
    
    public mutating func updateRequest(request: RemoteRequest<Delegate.Element.ID>) {
        self.request = request
//        self.store.revalidate(request: request)
    }
    
    public func revalidate() {
        self.store.revalidate(request: request)
    }
    
    public var wrappedValue: Delegate.Element? {
        get {
            return store.objects(request: request).first
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
    
    public var projectedValue: RemoteBinding<Delegate> {
        return RemoteBinding(id: wrappedValue?.id)
    }
}

public extension Binding {
    func unwrap<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
