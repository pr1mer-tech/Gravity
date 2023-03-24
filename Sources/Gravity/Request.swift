//
//  File.swift
//  
//
//  Created by Arthur Guiot on 23/03/2023.
//

import Foundation

public enum RemoteRequest<T: Codable & Hashable> {
    case ids([T])
    case id(T)
    case all
    
    static func +(lhs: RemoteRequest, rhs: RemoteRequest) -> RemoteRequest {
        switch (lhs, rhs) {
        case (.all, _), (_, .all):
            return .all
        case let (.id(id1), .id(id2)):
            return .ids([id1, id2])
        case let (.id(id), .ids(ids)) where !ids.contains(id):
            return .ids([id] + ids)
        case let (.ids(ids), .id(id)) where !ids.contains(id):
            return .ids([id] + ids)
        case let (.ids(ids1), .ids(ids2)):
            return .ids(Array(Set(ids1 + ids2)))
        default:
            return lhs
        }
    }

    static func +=(lhs: inout RemoteRequest, rhs: RemoteRequest) {
        lhs = lhs + rhs
    }

    static func -(lhs: RemoteRequest, rhs: RemoteRequest) -> RemoteRequest {
        switch (lhs, rhs) {
        case (_, .all):
            return .ids([])
        case let (.ids(ids), .ids(idsToRemove)):
            let idsSetToRemove = Set(idsToRemove)
            let filteredIds = ids.filter { !idsSetToRemove.contains($0) }
            return filteredIds.isEmpty ? .all : .ids(filteredIds)
        default:
            return lhs
        }
    }

    static func -=(lhs: inout RemoteRequest, rhs: RemoteRequest) {
        lhs = lhs - rhs
    }

    public var ids: [T] {
        switch self {
        case .ids(let ids):
            return ids
        case .id(let id):
            return [id]
        case .all:
            return []
        }
    }
}
