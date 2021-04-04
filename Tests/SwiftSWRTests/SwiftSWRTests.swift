import XCTest
@testable import SwiftSWR

final class SwiftSWRTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftSWR().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
