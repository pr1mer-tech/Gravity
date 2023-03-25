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
    
    public var wrappedValue: [Delegate.Element] {
        get {
            return store.objects(request: request)
        }
        nonmutating set {
            do {
                try store.save(elements: newValue, with: request)
            } catch {
                print("### Save to \(Delegate.Element.self) Store Error: \(error)")
            }
        }
    }
    
    public var projectedValue: Binding<[Delegate.Element]> {
        return .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
}
