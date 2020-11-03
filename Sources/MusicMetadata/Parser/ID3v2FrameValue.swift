import Foundation

typealias ArtistsList = [String: [String]]

let defaultEncoding = String.Encoding.isoLatin1

func parseID3v2FrameValues(data: Data, version: UInt8, header: ID3v2FrameHeader) -> String? {
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
      return nil
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

//private func parseSyncLyrics(data: Data, encoding: String.Encoding) -> [String] {
//  // skip text encoding (1 byte),
//  //      language (3 bytes),
//  //      time stamp format (1 byte),
//  //      content tagTypes (1 byte),
//  //      content descriptor (1 byte)
//
//  var offset = 7
//  while offset < data.count {
//    let newOffset = findZero(data)
//  }
//}

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
      print("WARNING: Failed to parse image MIME type")
      return nil
    }
    return (mimeType, endIndex)
  case 3, 4:
    let endIndex = findZero(data: data, encoding: defaultEncoding)
    guard let mimeType = data.getString(from: data.startIndex..<endIndex, encoding: defaultEncoding) else {
      print("WARNING: Failed to parse image MIME type")
      return nil
    }
    return (mimeType, endIndex)
  default:
    fatalError("Unexpected IDv3 version \(version)")
  }
}

private func parsePicture(data: Data, encoding: String.Encoding, version: UInt8) -> (String, UInt8, String, Data)? {
  guard let (mimeType, mimeTypeEndIndex) = parsePictureMimeType(data: data, version: version) else {
    return nil
  }

  let pictureType = data[mimeTypeEndIndex + 1]

  let fzero = findZero(data: data[mimeTypeEndIndex + 2..<data.endIndex], encoding: encoding)
  guard let description = data.getString(from: mimeTypeEndIndex + 2..<fzero, encoding: encoding) else {
    print("WARNING: Failed to parse image description")
    return nil
  }

  let pictureData = data[fzero + getNullTerminatorLength(encoding: encoding)..<data.endIndex]

  return (mimeType, pictureType, description, pictureData)
}

func parseID3v2FrameValue(data: Data, type: String, version: UInt8) -> String? {
  if data.count == 0 {
    return nil
  }

  let encoding = getTextEncoding(data[data.startIndex])
  var offset = 0

  let typeCase = type != "TXXX" && type.first == "T" ? "T*" : type
  switch typeCase {
    case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST":
      guard let text = data.getString(from: data.startIndex + 1..<data.endIndex, encoding: encoding) else {
        return nil
      }

      switch type {
        case "TMLC", "TIMPL", "IPLS":
          let output = splitID3v2Values(text)
          return "\(output)"

        case "TRK", "TRCK", "TPOS":
          return ".track(value: \(text))"

        case "TCOM", "TCON", "TEXT", "TOLY", "TOPE", "TPE1", "TSRC":
          return "\(splitID3v2Values(text))"

        case "PCS", "PCST":
          return version >= 4 ? "\(splitID3v2Values(text))" : "[\(text)]"

        default:
          return version >= 4 ? "\(splitID3v2Values(text))" : "[\(text)]"
      }

    case "TXXX":
      let frameData = data[data.startIndex + 1..<data.endIndex]
      guard let (identifier, value) = parseZeroSeparatedStringPair(data: frameData, encoding: encoding) else {
        return nil
      }
    
      return "\(identifier) -- \(value)"

    case "PIC", "APIC":
      let frameData = data[data.startIndex + 1..<data.endIndex]
      guard let (mimeType, pictureType, description, pictureData) = parsePicture(data: frameData, encoding: encoding, version: version) else {
        return nil
      }
      return "\(mimeType) -- \(pictureType) -- \(description)"

    case "CNT", "PCNT":
      return "\(data.getInt32BE())"

    case "SYLT":
      return "parseSyncLyrics(data)"
//
//    case "ULT", "USLT", "COM", "COMM":
//      return "parseUnsyncLyrics(data)"
//
//    case "UFID", "PRIV":
//      return "parseIndentifierData(data, encoding)"
//
//    case "POPM":
//      return "parsePopularimeter(data, encoding)"
//
//    case "GEOB":
//      return "parseGeneralEncapsulatedData(data)"
//
//    case "WCOM", "WCOP", "WOAF", "WOAR", "WOAS", "WORS", "WPAY", "WPUB":
//      return data.getString(from: 0..<data.count, encoding: encoding)
//
//    case "WXXX":
//      return "parseWXXX(data)"
//
//    case "MCDI":
//      return "parseMusicCDId"
//
    default:
      return "NOT IMPLEMENTED FRAME ID: \(type)"
  }
}

