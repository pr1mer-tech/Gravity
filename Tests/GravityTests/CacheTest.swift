//
//  CacheTest.swift
//  Gravity
//
//  Created by Arthur Guiot on 11/24/24.
//


import XCTest
@testable import Gravity // Replace with the actual module name

@MainActor
final class CacheTests: XCTestCase {
    // Define a mock Element that conforms to RemoteRepresentable
    struct MockElement: RemoteRepresentable, Codable, Equatable {
        typealias ID = Int
        let id: ID
        let value: String
    }
    
    var cache: Cache<MockElement>!
    
    override func setUp() {
        super.setUp()
        // Initialize the cache with a short entry lifetime for testing
        cache = Cache<MockElement>(reference: "testCache",
                                   dateProvider: Date.init,
                                   entryLifetime: 1.0,
                                   maximumEntryCount: 5)
    }
    
    override func tearDown() {
        // Clean up
        cache = nil
        super.tearDown()
    }
    
    func testInsertAndRetrieveValue() {
        let element = MockElement(id: 1, value: "Test Value")
        
        cache.insert(element, with: .id(1))
        
        let retrievedValue = cache.value(forKey: 1)
        
        XCTAssertEqual(retrievedValue, element, "Retrieved value should match inserted value.")
    }
    
    func testValueExpiration() {
        let element = MockElement(id: 1, value: "Test Value")
        
        cache.insert(element, with: .id(1))
        
        // Wait for entry to expire
        let expectation = XCTestExpectation(description: "Wait for entry to expire")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        let retrievedValue = cache.value(forKey: 1)
        
        XCTAssertNil(retrievedValue, "Value should be nil after expiration.")
    }
    
    func testRemoveValue() {
        let element = MockElement(id: 1, value: "Test Value")
        
        cache.insert(element, with: .id(1))
        
        cache.removeValue(forKey: 1)
        
        let retrievedValue = cache.value(forKey: 1)
        
        XCTAssertNil(retrievedValue, "Value should be nil after removal.")
    }
    
    func testMaximumEntryCount() {
        for i in 1...10 {
            let element = MockElement(id: i, value: "Value \(i)")
            cache.insert(element, with: .id(i))
        }
        
        XCTAssertEqual(cache.allKeys?.count, 5, "Cache should contain only maximumEntryCount entries.")
    }
    
    func testCachePersistence() throws {
        // Save the cache to disk
        let element = MockElement(id: 1, value: "Test Value")
        cache.insert(element, with: .id(1))
        
        try cache.saveToDisk()
        
        // Load the cache from disk
        let loadedCache = try Cache<MockElement>(withReference: "testCache")
        
        let retrievedValue = loadedCache.value(forKey: 1)
        
        XCTAssertEqual(retrievedValue, element, "Loaded cache should contain the saved element.")
    }
    
    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access test")
        let concurrentQueue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)
        let group = DispatchGroup()
        
        for i in 1...100 {
            group.enter()
            concurrentQueue.async {
                Task {
                    let element = MockElement(id: i, value: "Value \(i)")
                    await self.cache.insert(element, with: .id(i))
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            XCTAssertEqual(self.cache.allKeys?.count, self.cache.entryCache.countLimit, "Cache should contain maximumEntryCount entries after concurrent inserts.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRequestKeys() {
        let element1 = MockElement(id: 1, value: "Value 1")
        let element2 = MockElement(id: 2, value: "Value 2")
        let request = RemoteRequest.ids([1, 2])
        
        cache.insert(element1, with: request)
        cache.insert(element2, with: request)
        
        let keys = cache.keys(forRequest: request)
        
        XCTAssertEqual(Set(keys ?? []), Set([1, 2]), "Keys for request should match inserted keys.")
    }
    
    func testFuzzing() {
        let expectation = XCTestExpectation(description: "Fuzz test")
        let concurrentQueue = DispatchQueue(label: "fuzzQueue", attributes: .concurrent)
        let group = DispatchGroup()
        
        for _ in 1...1000 {
            group.enter()
            concurrentQueue.async {
                Task {
                    let operation = Int.random(in: 1...3)
                    let id = Int.random(in: 1...100)
                    let element = MockElement(id: id, value: "Value \(id)")
                    
                    switch operation {
                    case 1:
                        await self.cache.insert(element, with: .id(id))
                    case 2:
                        _ = await self.cache.value(forKey: id)
                    case 3:
                        await self.cache.removeValue(forKey: id)
                    default:
                        break
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            XCTAssertTrue(true, "Fuzz test completed without crashing.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testEquality() {
        let element = MockElement(id: 1, value: "Test Value")
        
        cache.insert(element, with: .id(1))
        
        let otherCache = Cache<MockElement>(reference: "testCache",
                                            dateProvider: Date.init,
                                            entryLifetime: 1.0,
                                            maximumEntryCount: 5)
        otherCache.insert(element, with: .id(1))
        
        XCTAssertEqual(cache, otherCache, "Caches with the same content should be equal.")
    }
}
