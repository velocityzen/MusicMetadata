import XCTest
@testable import MusicMetadata

final class ID3v2Tests: XCTestCase {
  func testID3v24() {
    let url = URL(fileURLWithPath: "../Samples/id3v2.4.mp3", isDirectory: false)
    let metadata = try! getMusicMetadata(for: url)!
    
    XCTAssertEqual(metadata.type, .mp3)
    XCTAssertEqual(metadata.ext, "mp3")
    XCTAssertEqual(metadata.mime, "audio/mpeg")
    XCTAssertEqual(metadata.title, "Home")
    XCTAssertEqual(metadata.artist, "Explo")
  }
  
  static var allTests = [
    ("testID3v24", testID3v24),
  ]
}
