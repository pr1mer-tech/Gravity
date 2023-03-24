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
    }
    
    public init(waitForRequest: Bool) {
        self.store = Delegate.shared.store
    }
    
    public mutating func updateRequest(request: RemoteRequest<Delegate.Element.ID>) {
        self.request = request
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
                try store.save(newValue, with: request)
            } catch {
                print("### Save to \(Delegate.Element.self) Store Error: \(error)")
            }
        }
    }
    
    public var projectedValue: RemoteBinding<Delegate>? {
        guard let id = wrappedValue?.id else { return nil }
        guard Delegate.shared.store.object(id: id) != nil else { return nil }
        return RemoteBinding(id: id, request: request)
    }
}
