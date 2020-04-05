import XCTest
@testable import MusicMetadata

final class MusicMetadataTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MusicMetadata().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
