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
    
    func testSavePerformance() throws {
        // This is an example of a performance test case.
        let store = UserBase.shared.store
        self.measure {
            for _ in 0...2000 {
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
                guard !store.objects(request: .id(id)).isEmpty else { return XCTFail("Empty object") }
            }
        }
    }
}
