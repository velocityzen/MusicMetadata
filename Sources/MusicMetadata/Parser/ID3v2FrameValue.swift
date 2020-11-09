import Foundation

enum ParserResult<A, B> {
  case success(A)
  case failure(B)
}

struct Frame {
  let id: String
  let title: String
  let value: FrameValue
}

enum FrameValue {
  case invalid(error: String)
  case stringArray([String])
  case userUrlLink(UserUrlLink)
  case credits([Credit])
  case position(Position)
  case encryption(AudioEncryption)
}

typealias ArtistsList = [String: [String]]

struct UserUrlLink {
  let description: String
  let url: URL
}

struct MusicCDId {
  let tableOfContents: Data
}

struct Credit {
  let role: String
  let names: [String]
}

enum Position {
  case number(Int)
  case numberWithTotal(trackNumber: Int, totalNumber: Int)
  case string(String)
}

struct AudioEncryption {
  struct Preview {
    let startFrame: Int
    let numFrames: Int
  }
  
  let ownerIdentifier: String
  let preview: Preview?
  let encryptionInfo: Data?
}

private let defaultEncoding = String.Encoding.isoLatin1

private func involvedPersonPairToCredit(pair: (String, String)) -> Credit {
  Credit(
    role: pair.0,
    names: pair.1
      .split(separator: ",")
      .map(String.init)
  )
}

private func wrap<T>(_ parser: @escaping (Data) -> ParserResult<T, String>, type: @escaping (T) -> FrameValue) -> (Data) -> FrameValue {
  return { data in
    switch parser(data) {
    case .success(let value):
      return type(value)
    case .failure(let error):
      return .invalid(error: error)
    }
  }
}

let parsers: [String: (Data) -> FrameValue] = [
  "AENC": wrap(parseAudioEncryptionFrame, type: FrameValue.encryption)
]

func parseID3v2FrameValue(data: Data, type: String, version: UInt8) -> FrameValue {
  if data.count == 0 {
    return .invalid(error: "Frame contains no data")
  }
  
  let encoding = getTextEncoding(data[data.startIndex])
  let typeCase = type != "TXXX" && type.first == "T" ? "T*" : type
  
  switch typeCase {
    
  case "AENC":
    return parser(parseAudioEncryptionFrame, type: FrameValue.encryption)(data)
    
  case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST":
    guard let text = data.getString(from: data.startIndex + 1..<data.endIndex, encoding: encoding) else {
      return .invalid(error: "TODO ERROR PARSING")
    }
    
    switch type {
    case "TMCL", "TIPL", "IPLS":
      return .credits(splitID3v2Values(text).toPairs().map(involvedPersonPairToCredit))
      
    case "TRK", "TRCK", "TPOS":
      return .position(parsePosition(string: text))
      
    case "TCON":
      return .stringArray(parseGenre(string: text))
      
    default:
      return .invalid(error: version >= 4 ? "\(splitID3v2Values(text))" : "[\(text)]")
    }
    
  case "TXXX":
    let frameData = data[data.startIndex + 1..<data.endIndex]
    guard let (identifier, value) = parseZeroSeparatedStringPair(data: frameData, encoding: encoding) else {
      return .invalid(error: "TODO")
    }
    
    return .invalid(error: "\(identifier) -- \(value)")
    
  case "PIC", "APIC":
    guard let (mimeType, pictureType, description, pictureData) = parsePictureFrame(data: data, version: version) else {
      return .invalid(error: "TODO")
    }
    return .invalid(error: "\(mimeType) -- \(pictureType) -- \(description) -- data len: \(pictureData.count)")
    
  case "CNT", "PCNT":
    return .invalid(error: "\(data.getUInt32BESafe())")
    
  case "SYLT":
    return .invalid(error: "\(parseSyncTextFrame(data: data) ?? "")")
    
  case "ULT", "USLT", "COM", "COMM":
    return .invalid(error: "\(parseUnsyncTextFrame(data: data) ?? "")")
    
  case "UFID", "PRIV":
    guard let (identifier, value) = parseZeroSeparatedStringDataPair(data: data, encoding: encoding) else {
      return .invalid(error: "TODO")
    }
    return .invalid(error: "\(identifier) -- data len: \(value.count)")
    
  case "POPM":
    return .invalid(error: "\(parsePopularimeterFrame(data: data) ?? "")")
    
  case "GEOB":
    return .invalid(error: "\(parseGeneralEncapsulatedDataFrame(data: data) ?? "")")
    
  case "WCOM", "WCOP", "WOAF", "WOAR", "WOAS", "WORS", "WPAY", "WPUB":
    return .invalid(error: "\(parseUrlLinkFrame(data: data) ?? "")")
    
  case "WXXX":
    return .invalid(error: "\(parseUserUrlLinkFrame(data: data))")
    
  case "WFD", "WFED":
    return .invalid(error: "\(parseApplePodcastFeedUrlFrame(data: data) ?? "")")
    
  case "MCDI":
    return .invalid(error: "\(parseMusicCDIdentifier(data: data))")
  
  default:
    return .invalid(error: "Unsupported frame type \"\(type)\"")
  }
}

func parseID3v2FrameValues(data: Data, version: UInt8, header: ID3v2FrameHeader) -> FrameValue {
  switch version {
  case 2:
    return parseID3v2FrameValue(data: data, type: header.id, version: version)
    
  case 3, 4:
    var data = data
    if header.flags?.formatUnsynchronisation ?? false {
      data = removeUnsyncBytes(data)
    }
    
    if header.flags?.formatDataLengthIndicator ?? false {
      data = data[4..<data.count]
    }
    
    return parseID3v2FrameValue(data: data, type: header.id, version: version)
    
  default:
    return .invalid(error: "TODO")
  }
}

func removeUnsyncBytes(_ data: Data) -> Data {
  var readI = data.startIndex
  var writeI = data.startIndex
  var result = data
  while (readI < data.endIndex) {
    if (readI != writeI) {
      result[writeI] = data[readI]
    }
    readI += data[readI] == 0xff && data[readI + 1] == 0 ? 2 : 1
    writeI += 1
  }
  if (readI < data.count) {
    writeI += 1
    result[writeI] = data[readI];
  }
  return result.subdata(in: data.startIndex..<writeI)
}

// id3v2.4 defines that multiple T* values are separated by 0x00
// id3v2.3 defines that TCOM, TEXT, TOLY, TOPE & TPE1 values are separated by /
private func splitID3v2Values(_ str: String) -> [String] {
  let values = str.split(separator: "\u{00}")
  
  if values.count > 1 {
    return trimArray(values)
  }
  
  return trimArray(str.split(separator: "/"))
}

private func trimArray(_ array: [Substring]) -> [String] {
  return array.map {
    $0
      .replacingOccurrences(of: "\u{00}", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

// Converts TMCL (Musician credits list) or TIPL (Involved people list)
private func parseID3v2ArtistFunctionList(_ entries: [String]) -> ArtistsList {
  var result = [String: [String]]()
  
  for i in stride(from: 0, to: entries.count, by: 2) {
    let names = entries[i + 1]
      .split(separator: ",")
      .map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    
    if result[entries[i]] != nil {
      result[entries[i]]?.append(contentsOf: names)
    } else {
      result[entries[i]] = names
    }
  }
  
  return result;
}

enum SyncTextTimeStampUnit: Int {
  case unknown = 0
  case mpegFrame = 1
  case millisecond = 2
}

enum SyncTextContentType: Int {
  case other = 0
  case lyrics = 1
  case textTranscription = 2
  case movementOrPartName = 3
  case events = 4
  case chord = 5
  case triviaOrPopUpInformation = 6
  case urlsToWebPages = 7
  case urlsToImages = 8
}

struct SyncTextItem {
  let timeStamp: Int
  let text: String
}

private func parseSyncTextFrame(data: Data) -> String? {
  // <Header for 'Synchronised lyrics/text', ID: "SYLT">
  // Text encoding        $xx
  // Language             $xx xx xx
  // Time stamp format    $xx
  // Content type         $xx
  // Content descriptor   <text string according to encoding> $00 (00)
  let textEncoding = getTextEncoding(data[data.startIndex])
  
  let languageStartIndex = data.startIndex + 1
  let languageEndIndex = languageStartIndex + 3
  guard let language = data.getString(from: languageStartIndex..<languageEndIndex, encoding: defaultEncoding) else {
    fatalError("Unable to parse synchronized text language")
  }
  
  guard let timeStampFormat = SyncTextTimeStampUnit(rawValue: Int(data[languageEndIndex])) else {
    fatalError("Unable to parse synchronized text time stamp format")
  }
  
  guard let contentType = SyncTextContentType(rawValue: Int(data[languageEndIndex + 1])) else {
    fatalError("Unable to parse synchronized text content type")
  }
  
  let contentDescriptorStartIndex = languageEndIndex + 2
  let contentDescriptorEndIndex = findZero(data: data[contentDescriptorStartIndex..<data.endIndex], encoding: textEncoding)
  guard let contentDescriptor = data.getString(from: contentDescriptorStartIndex..<contentDescriptorEndIndex, encoding: textEncoding) else {
    fatalError("Unable to parse synchronized text content descriptor")
  }
  
  // Each sync has the following structure:
  // Terminated text to be synced (typically a syllable)
  // Sync identifier (terminator to above string)   $00 (00)
  // Time stamp                                     $xx (xx ...)
  var syncTextItems: [SyncTextItem] = []
  var currentIndex = contentDescriptorEndIndex + 1
  while currentIndex < data.endIndex {
    let textEndIndex = findZero(data: data[currentIndex..<data.endIndex], encoding: textEncoding)
    guard let text = data.getString(from: currentIndex..<textEndIndex, encoding: textEncoding) else {
      fatalError("Unable to parse synchronized text item")
    }
    let timeStampStartIndex = textEndIndex + 1
    let timeStamp = data.getInt32BE(offset: timeStampStartIndex)
    syncTextItems.append(SyncTextItem(timeStamp: timeStamp, text: text))
    currentIndex = timeStampStartIndex + 4
  }
  
  
  let debutStr = syncTextItems.reduce("") { (outputSoFar, item) -> String in
    return "\(outputSoFar)\n    \(String(item.timeStamp).padding(toLength: 6, withPad: " ", startingAt: 0)): \(item.text)"
  }
  
  return "\(language) -- \(timeStampFormat) -- \(contentType) -- \(contentDescriptor) -- \(debutStr)"
}

private func parseUnsyncTextFrame(data: Data) -> String? {
  // <Header for 'Unsynchronised lyrics/text transcription', ID: "USLT">
  // Text encoding        $xx
  // Language             $xx xx xx
  // Content descriptor   <text string according to encoding> $00 (00)
  // Lyrics/text          <full text string according to encoding>
  let textEncoding = getTextEncoding(data[data.startIndex])
  
  let languageStartIndex = data.startIndex + 1
  let languageEndIndex = languageStartIndex + 3
  guard let language = data.getString(from: languageStartIndex..<languageEndIndex, encoding: defaultEncoding) else {
    fatalError("Unable to parse unsynchronized text language")
  }
  
  let contentDescriptorStartIndex = languageEndIndex
  let contentDescriptorEndIndex = findZero(data: data[contentDescriptorStartIndex..<data.endIndex], encoding: textEncoding)
  guard let contentDescriptor = data.getString(from: contentDescriptorStartIndex..<contentDescriptorEndIndex, encoding: textEncoding) else {
    fatalError("Unable to parse unsynchronized text content")
  }
  
  let textStartIndex = contentDescriptorEndIndex + getNullTerminatorLength(encoding: textEncoding)
  guard let text = data.getString(from: textStartIndex..<data.endIndex, encoding: textEncoding) else {
    fatalError("Unable to parse unsynchronized text value")
  }
  
  return "\(language) -- \(contentDescriptor) -- \(text)"
}

private func parseGeneralEncapsulatedDataFrame(data: Data) -> String? {
  // <Header for 'General encapsulated object', ID: "GEOB">
  // Text encoding          $xx
  // MIME type              <text string> $00
  // Filename               <text string according to encoding> $00 (00)
  // Content description    <text string according to encoding> $00 (00)
  // Encapsulated object    <binary data>
  let textEncoding = getTextEncoding(data[data.startIndex])
  
  let mimeTypeStartIndex = data.startIndex + 1
  let mimeTypeEndIndex = findZero(data: data[mimeTypeStartIndex..<data.endIndex], encoding: defaultEncoding)
  guard let mimeType = data.getString(from: mimeTypeStartIndex..<mimeTypeEndIndex, encoding: defaultEncoding) else {
    fatalError("Unable to parse general encapsulated data MIME type")
  }
  
  let fileNameStartIndex = mimeTypeEndIndex + getNullTerminatorLength(encoding: defaultEncoding)
  let fileNameEndIndex = findZero(data: data[fileNameStartIndex..<data.endIndex], encoding: textEncoding)
  guard let fileName = data.getString(from: fileNameStartIndex..<fileNameEndIndex, encoding: textEncoding) else {
    fatalError("Unable to parse general encapsulated data file name")
  }
  
  let contentDescriptionStartIndex = fileNameEndIndex + getNullTerminatorLength(encoding: textEncoding)
  let contentDescriptionEndIndex = findZero(data: data[contentDescriptionStartIndex..<data.endIndex], encoding: textEncoding)
  guard let contentDescription = data.getString(from: contentDescriptionStartIndex..<contentDescriptionEndIndex, encoding: textEncoding) else {
    fatalError("Unable to parse general encapsulated data content description")
  }
  
  let encapsulatedObjectStartIndex = contentDescriptionEndIndex + getNullTerminatorLength(encoding: textEncoding)
  let encapsulatedObject = data[encapsulatedObjectStartIndex..<data.endIndex]
  
  return "\(mimeType) -- \(fileName) -- \(contentDescription) -- data len: \(encapsulatedObject.count)"
}

private func parsePopularimeterFrame(data: Data) -> String? {
  let emailEndIndex = findZero(data: data, encoding: defaultEncoding)
  guard let email = data.getString(from: data.startIndex..<emailEndIndex, encoding: defaultEncoding) else {
    fatalError("Unable to parse popularmeter email")
  }
  
  let ratingIndex = emailEndIndex + getNullTerminatorLength(encoding: defaultEncoding)
  let rating = data[emailEndIndex + getNullTerminatorLength(encoding: defaultEncoding)]
  
  let counter = data.getUInt32BESafe(offset: ratingIndex + 1)
  
  return "\(email) -- rating: \(rating) -- \(counter)"
}

private func getNullTerminatorLength(encoding: String.Encoding) -> Int {
  switch encoding {
  case .utf8, .isoLatin1:
    return 1
  case .utf16, .utf16BigEndian, .utf16LittleEndian:
    return 2
  default:
    fatalError("Not implemented for encoding: \(encoding)")
  }
}

private func findZero(data: Data, encoding: String.Encoding) -> Data.Index {
  guard data.count > 1 else { return data.endIndex }
  var i = data.startIndex
  switch getNullTerminatorLength(encoding: encoding) {
  case 1:
    while data[i] != 0 {
      if (i >= data.endIndex) {
        return data.endIndex
      }
      i += 1
    }
  case 2:
    while data[i] != 0 || data[i+1] != 0 {
      if (i + 1 >= data.endIndex) {
        return data.endIndex
      }
      i += 2
    }
  default:
    fatalError("Not implemented for encoding: \(encoding)")
  }
  return i
}

private func parseZeroSeparatedStringDataPair(data: Data, encoding: String.Encoding) -> (String, Data)? {
  let fzero = findZero(data: data, encoding: encoding)
  guard let identifier = data.getString(from: data.startIndex..<fzero, encoding: encoding) else {
    return nil
  }
  let value = data[fzero + getNullTerminatorLength(encoding: encoding)..<data.endIndex]
  return (identifier, value)
}

private func parseZeroSeparatedStringPair(data: Data, encoding: String.Encoding) -> (String, String)? {
  guard let (firstString, secondData) = parseZeroSeparatedStringDataPair(data: data, encoding: encoding),
        let secondString = String(data: secondData, encoding: encoding) else {
    return nil
  }
  return (firstString, secondString)
}

private func parseInt(_ str: String) -> Int? {
  return Int(str) ?? nil
}

private func version2ImageFormatToMimeType(imageFormat: String?) -> String? {
  switch imageFormat?.lowercased() {
  case "png":
    return "image/png"
  case "jpg":
    return "image/jpeg"
  case nil:
    return nil
  default:
    print("WARNING: Unsupported IDv3.2 image format: \(String(describing: imageFormat))")
    return imageFormat
  }
}

private func parsePictureMimeType(data: Data, version: UInt8) -> (String, Data.Index)? {
  switch version {
  case 2:
    let endIndex = data.startIndex + 3
    let imageFormat = data.getString(from: data.startIndex..<endIndex, encoding: defaultEncoding)
    guard let mimeType = version2ImageFormatToMimeType(imageFormat: imageFormat) else {
      fatalError("Unable to parse attached picture MIME type")
    }
    let nextItemIndex = endIndex + getNullTerminatorLength(encoding: defaultEncoding)
    return (mimeType, nextItemIndex)
  case 3, 4:
    let endIndex = findZero(data: data, encoding: defaultEncoding)
    guard let mimeType = data.getString(from: data.startIndex..<endIndex, encoding: defaultEncoding) else {
      fatalError("Unable to parse attached picture MIME type")
    }
    let nextItemIndex = endIndex + getNullTerminatorLength(encoding: defaultEncoding)
    return (mimeType, nextItemIndex)
  default:
    fatalError("Unexpected IDv3 version \(version)")
  }
}

private func parsePictureFrame(data: Data, version: UInt8) -> (String, UInt8, String, Data)? {
  // <Header for 'Attached picture', ID: "APIC">
  // Text encoding      $xx
  // MIME type          <text string> $00
  // Picture type       $xx
  // Description        <text string according to encoding> $00 (00)
  // Picture data       <binary data>
  let textEncoding = getTextEncoding(data[data.startIndex])
  
  let mimeTypeData = data[data.startIndex + 1..<data.endIndex]
  guard let (mimeType, pictureTypeStartIndex) = parsePictureMimeType(data: mimeTypeData, version: version) else {
    fatalError("Unable to parse attached picture MIME type")
  }
  
  let pictureType = data[pictureTypeStartIndex]
  
  let descriptionStartIndex = pictureTypeStartIndex + 1
  let descriptionEndIndex = findZero(data: data[descriptionStartIndex..<data.endIndex], encoding: textEncoding)
  guard let description = data.getString(from: descriptionStartIndex..<descriptionEndIndex, encoding: textEncoding) else {
    fatalError("Unable to parse attached picture description")
  }
  
  let pictureDataStartIndex = descriptionEndIndex + getNullTerminatorLength(encoding: textEncoding)
  guard pictureDataStartIndex <= data.endIndex else {
    return nil
  }
  let pictureData = data[pictureDataStartIndex..<data.endIndex]
  
  return (mimeType, pictureType, description, pictureData)
}

private func parseUrlLinkFrame(data: Data) -> String? {
  return String(data: data, encoding: defaultEncoding)
}

private func parseUserUrlLinkFrame(data: Data) -> ParserResult<UserUrlLink, String> {
  // <Header for 'User defined URL link frame', ID: "WXXX">
  // Text encoding     $xx
  // Description       <text string according to encoding> $00 (00)
  // URL               <text string>
  if (data.count < 3) {
    return .failure("Unable to parse user URL link. Data size too small.")
  }
  let textEncoding = getTextEncoding(data[data.startIndex])
  
  let descriptionStartIndex = data.startIndex + 1
  let descriptionEndIndex = findZero(data: data[descriptionStartIndex..<data.endIndex], encoding: textEncoding)
  guard let description = data.getString(from: descriptionStartIndex..<descriptionEndIndex, encoding: textEncoding) else {
    return .failure("Unable to parse user URL link description")
  }
  
  let urlStartIndex = descriptionEndIndex + getNullTerminatorLength(encoding: textEncoding)
  guard let urlString = data.getString(from: urlStartIndex..<data.endIndex, encoding: defaultEncoding) else {
    return .failure("Unable to parse user URL data")
  }
  
  guard let url = URL(string: urlString) else {
    return .failure("Unable to parse user URL string")
  }
  
  let result = UserUrlLink(description: description, url: url)
  
  return .success(result)
}

private func parseApplePodcastFeedUrlFrame(data: Data) -> String? {
  let textEncoding = getTextEncoding(data[data.startIndex])
  guard let url = data.getString(from: data.startIndex + 1..<data.endIndex, encoding: textEncoding) else {
    fatalError("Unable to parse Apple podcast feed URL value")
  }
  
  return "\(url)"
}

private func parseMusicCDIdentifier(data: Data) -> ParserResult<MusicCDId, String> {
  return .success(MusicCDId(tableOfContents: data))
}

private func parsePosition(string: String) -> Position {
  func parseNumberWithTotal(_ string: String) -> Position? {
    let parts = string.split(separator: "/")
    guard parts.count == 2 else {
      return nil
    }
    guard let trackNumber = Int(parts[0]), let totalNumber = Int(parts[1]) else {
      return nil
    }
    return .numberWithTotal(trackNumber: trackNumber, totalNumber: totalNumber)
  }
  
  func parseNumberWithoutTotal(_ string: String) -> Position? {
    guard let intValue = Int(string) else {
      return nil
    }
    return .number(intValue)
  }
  
  return parseNumberWithTotal(string) ??
    parseNumberWithoutTotal(string) ??
    .string(string)
}

private func parseGenre(string: String) -> [String] {
  // The value is a zero separated string of genres.
  // A genre value can be either any string, or a ID3v1 genre identifer number as a string.
  func parseID3v1Genre(_ string: String) -> String? {
    Int(string).flatMap { ID3v1Genres[safeIndex: $0] }
  }
  
  return splitID3v2Values(string).map { parseID3v1Genre($0) ?? $0 }
}

private func parseAudioEncryptionFrame(_ data: Data) -> ParserResult<AudioEncryption, String> {
  // <Header for 'Audio encryption', ID: "AENC">
  // Owner identifier   <text string> $00
  // Preview start      $xx xx
  // Preview length     $xx xx
  // Encryption info    <binary data>
  let ownerIdEndIndex = findZero(data: data, encoding: defaultEncoding)
  let ownerId = data.getString(from: data.startIndex..<ownerIdEndIndex, encoding: defaultEncoding)
  
  let previewStartStartIndex = ownerIdEndIndex + getNullTerminatorLength(encoding: defaultEncoding)
  let previewStart = data.getUInt16BESafe(offset: previewStartStartIndex)
  
  fatalError("TODO")
}
