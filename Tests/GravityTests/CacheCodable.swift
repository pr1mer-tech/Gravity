//
//  CacheCodable.swift
//
//
//  Created by Arthur Guiot on 22/03/2023.
//

import XCTest
@testable import Gravity

@MainActor
final class CacheCodable: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCoding() throws {
        let store = UserBase.shared.store
        var uuids = [UUID]()
        for _ in 0...1000 {
            let id = UUID()
            try? store.save(User(id: id, email: "example@example.com"), requestPush: false)
            uuids.append(id)
        }
        
        self.measure {
            guard let data = try? JSONEncoder().encode(UserBase.shared.store.cache) else { return }
            let decoded = try? JSONDecoder().decode(Cache<UserBase.Element>.self, from: data)
            
            XCTAssertEqual(UserBase.shared.store.cache, decoded)
        }
    }
}
