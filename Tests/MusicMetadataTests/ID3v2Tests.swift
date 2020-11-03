import XCTest
@testable import MusicMetadata

final class ID3v2Tests: XCTestCase {
  func testID3v24() {
//    let url = URL(fileURLWithPath: "/Users/timojaask/projects/MusicMetadata/Tests/Samples/id3v2.4-musicbrainz.mp3", isDirectory: false)
//    let url = URL(fileURLWithPath: "/Users/timojaask/projects/MusicMetadata/Tests/Samples/id3v2.4.mp3", isDirectory: false)
    let url = URL(fileURLWithPath: "/Users/timojaask/projects/MusicMetadata/Tests/Samples/id3v2-lyrics.mp3", isDirectory: false)
//    let url = URL(fileURLWithPath: "/Users/timojaask/projects/MusicMetadata/Tests/Samples/mp3/From-The-Machine-World-SYLT.mp3", isDirectory: false)
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
