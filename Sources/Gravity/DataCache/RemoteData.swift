//
//  File.swift
//  
//
//  Created by Arthur Guiot on 09/04/2023.
//

import Foundation

public protocol RemoteData<ObjectData>: Codable, Hashable, Identifiable where ID: Codable & Hashable {
    associatedtype ObjectData
    
    static func object(from: Data) -> ObjectData
}
