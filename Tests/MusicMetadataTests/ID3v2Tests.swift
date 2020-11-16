import XCTest
@testable import MusicMetadata

private let mp3Files = [
  "mp3/APEv2+Lyrics3v2.mp3",
  "mp3/Sleep Away.mp3",
  "mp3/adts-0-frame.mp3",
  "mp3/empty-picture-tag.mp3",
  "mp3/id3v2-lyrics-USLT.mp3",
  "mp3/issue-331.apev2.mp3",
  "mp3/issue-362.apev1.mp3",
  "mp3/issue-381.mp3",
  "mp3/issue-406-geob.mp3",
  "mp3/issue-453.mp3",
  "mp3/issue-471.mp3",
  "mp3/issue-502.mp3",
  "mp3/issue-641.mp3",
  "mp3/null-separator.id3v2.3.mp3",
  "mp3/pr-544-id3v24.mp3",
  "02-Yeahs-It's Blitz! 2.mp3",
  "04 - You Don't Know.mp3",
  "04-Strawberry.mp3",
  "07 - I'm Cool.mp3",
  "29 - Dominator.mp3",
  "Dethklok-mergeTagHeaders.mp3",
  "Discogs - Beth Hart - Sinner's Prayer [id3v2.3].mp3",
  "MusicBrainz - Beth Hart - Sinner's Prayer [id3v2.3].V2.mp3",
  "MusicBrainz - Beth Hart - Sinner's Prayer [id3v2.4].V2.mp3",
  "Their - They're - Therapy - 1sec.mp3",
  "audio-frame-header-bug.mp3",
  "bug-id3v2-unknownframe.mp3",
  "bug-non ascii chars.mp3",
  "bug-unkown encoding.mp3",
  "bug-utf16bom-encoding.mp3",
  "id3-multi-01.mp3",
  "id3-multi-02.mp3",
  "id3v2-duration-allframes.mp3",
  "id3v2-lyrics.mp3",
  "id3v2-utf16.mp3",
  "id3v2.2.mp3",
  "id3v2.3.mp3",
  "id3v2.4-musicbrainz.mp3",
  "id3v2.4.mp3",
  "incomplete.mp3",
  "issue_66.mp3",
  "issue_77_empty_tag.mp3",
  "outofbounds.mp3",
  "regress-GH-56.mp3",
  "issue-100.mp3", // should decode POPM without a counter field
  "issue_56.mp3", // should decode PeakValue without data
  "id3v2-xheader.mp3", // should be able to read id3v2 files with extended headers
  "issue_69.mp3", // should respect null terminated tag values correctly
  "silence-2s-16000 [no-tags].CBR-128.mp3", // should handle MP3 without any tags
  "mp3/issue-554.mp3", // should handlle corrupt LAME header
  "Luomo - Tessio (Spektre Remix) ID3v10.mp3", // should decode ID3v1.0 with undefined tags
  "MusicBrainz - Beth Hart - Sinner's Prayer [no-tags].V4.mp3",
  "id3v1_Blood_Sugar.mp3", // should be able to read an ID3v1 tag
  "mp3/issue-347.mp3" // should handle MPEG 2.5 Layer III
]

private func mp3Url(mp3File: String) -> URL {
  return URL(fileURLWithPath: "/Users/timojaask/projects/MusicMetadata/Tests/Samples/\(mp3File)", isDirectory: false)
}

final class ID3v2Tests: XCTestCase {
  
  func testID3v24() {
    mp3Files.forEach { (mp3File) in
//    ["Luomo - Tessio (Spektre Remix) ID3v10.mp3"].forEach { (mp3File) in
      let url = mp3Url(mp3File: mp3File)
//      print("MP3 FILE: \(mp3File) ========================================================")
      
      let metadata = try! getMusicMetadata(for: url)!
    }
//    let url = mp3Url(mp3File: mp3Files[0])
//
//    let metadata = try! getMusicMetadata(for: url)!
//
//    XCTAssertEqual(metadata.type, .mp3)
//    XCTAssertEqual(metadata.ext, "mp3")
//    XCTAssertEqual(metadata.mime, "audio/mpeg")
//    XCTAssertEqual(metadata.title, "Home")
//    XCTAssertEqual(metadata.artist, "Explo")
  }
  
  static var allTests = [
    ("testID3v24", testID3v24),
  ]
}
