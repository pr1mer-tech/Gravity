//
//  Utility.swift
//  
//
//  Created by Arthur Guiot on 23/03/2023.
//

import Foundation
@testable import Gravity

struct User: RemoteRepresentable {
    var id: UUID
    var name: String?
    var email: String
    var birthday: Date?
    var gender: Gender?
    var profilePicture: String?
    
    enum Gender: String, Codable {
        case male
        case female
    }
}

struct UserBase: RemoteObjectDelegate {
    typealias Element = User
    
    var store = try! Store<UserBase>(reference: "users", maximumEntryCount: 1100)
    
    func pull(request: Gravity.RemoteRequest<UUID>) async throws -> [User] {
        return request.ids.map { id in
            User(id: id, email: "hello@world.com")
        }
    }
    
    func push(elements: [User]) async throws {
        fatalError("Not implemented")
    }
    
    static var shared = UserBase()
}
