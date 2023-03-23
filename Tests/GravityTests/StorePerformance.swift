//
//  StorePerformance.swift
//  
//
//  Created by Arthur Guiot on 22/03/2023.
//

import XCTest
@testable import Gravity

@MainActor
final class StorePerformance: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testSavePerformance() throws {
        // This is an example of a performance test case.
        let store = UserBase.shared.store
        self.measure {
            for _ in 0...1000 {
                try? store.save(User(id: UUID(), email: "example@example.com"), requestPush: false)
            }
        }
    }

    func testReadPerformance() throws {
        // This is an example of a performance test case.
        let store = UserBase.shared.store
        var uuids = [UUID]()
        for _ in 0...1000 {
            let id = UUID()
            try? store.save(User(id: id, email: "example@example.com"), requestPush: false)
            uuids.append(id)
        }
        self.measure {
            for id in uuids {
                guard store.object(id: id) != nil else { return }
            }
        }
        // Test
        store.objects()
    }
}

struct User: Codable, Identifiable {
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try Swift.withUnsafeBytes(of: self) { try body($0) }
    }
    
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
    
    var store = try! Store<UserBase>(reference: "users")
    
    func pull(id: UUID) async throws -> User {
        fatalError("Not implemented")
    }
    
    func pull(ids: [UUID]) async throws -> [User] {
        fatalError("Not implemented")
    }
    
    func push(elements: [User]) async throws {
        fatalError("Not implemented")
    }
    
    static var shared = UserBase()
}
