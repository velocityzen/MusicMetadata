import Foundation

typealias ArtistsList = [String: [String]]

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
  var readI = 0
  var writeI = 0
  var result = data
  while (readI < data.count - 1) {
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
  return result.subdata(in: 0..<writeI)
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

private func parseInt(_ str: String) -> Int? {
  return Int(str) ?? nil
}

func parseID3v2FrameValue(data: Data, type: String, version: UInt8) -> MetadataField? {
  if data.count == 0 {
    return nil
  }

  let encoding = getTextEncoding(data[0])
  var offset = 0

  let typeCase = type != "TXXX" && type.first == "T" ? "T*" : type
  switch typeCase {
    case "T*", "IPLS":
      guard let text = data.getString(from: 1..<data.count, encoding: encoding) else {
        return nil
      }

      switch type {
        case "TMLC", "TIMPL", "IPLS":
          return "parseArtistFunctionList(splitValues(text))"

        case "TRK", "TRCK":
          guard let value = parseInt(text) else {
            return nil
          }
          return .track(value: value)
        
        case "TPOS":
          guard let value = parseInt(text) else {
            return nil
          }
          return .disk(value: value)

        case "TCOM", "TCON", "TEXT", "TOLY", "TOPE", "TPE1", "TSRC":
          return splitValues(text)

        default:
          return version >= 4 ? splitValue(text) : [text]
      }

      return text

    case "TXXX":
      // TODO
      return "data"

    case "PIC", "APIC":
      return "parsePictures(data: Data, version)"

    case "CNT", "PCNT":
      return data.getInt32BE()
//
//    case "SYLT":
//      return "parseSyncLyrics(data)"
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
      return nil
  }
}

