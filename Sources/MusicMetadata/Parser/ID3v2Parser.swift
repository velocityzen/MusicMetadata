import Foundation

func parseID3v2Data(data: Data, version: UInt8) -> Metadata? {
  guard let frameHeaderSize = getID3v2FrameHeaderSize(version) else {
    return nil
  }
  
  var metadata = Metadata()
  var offset: Int = 0
  while offset + frameHeaderSize < data.count {
    guard let frameHeader = parseID3v2FrameHeader(
      data: data.subdata(in: offset..<offset + frameHeaderSize),
      version: version
    ) else {
      break
    }

    if frameHeader.dataSize < 1 { break }
    
    offset += frameHeaderSize
    var frameData = data[offset..<offset + frameHeader.dataSize]
    if version == 3 || version == 4 {
      if frameHeader.flags?.formatUnsynchronisation ?? false {
        frameData = removeUnsyncBytes(frameData)
      }

      if frameHeader.flags?.formatDataLengthIndicator ?? false {
        frameData = frameData[4..<frameData.count]
      }
    }

    let frameIdCase = frameHeader.id != "TXXX" && frameHeader.id.first == "T" ? "T*" : frameHeader.id

    switch frameIdCase {
    
    case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST" :
      guard let text = parseID3v2FrameValue(data: frameData, type: frameHeader.id, version: version) else {
        fatalError()
        break
      }
      print("\(frameHeader.id) -- \(text)")
      
    case "TXXX":
      guard let text = parseID3v2FrameValue(data: frameData, type: frameHeader.id, version: version) else {
        fatalError()
        break
      }
      print("\(frameHeader.id) -- \(text)")
      
    case "APIC":
        guard let text = parseID3v2FrameValue(data: frameData, type: frameHeader.id, version: version) else {
          fatalError()
          break
        }
        print("\(frameHeader.id) -- \(text)")

    case "SYLT":
      fatalError("LYRICS!!!")

    case "PRIV":
      var ownerIdentifier: String? = nil
      var privateData: Data? = nil
      for i in frameData.startIndex..<frameData.endIndex {
        if frameData[i] == 0 {
          let ownerIdentifierData = frameData[frameData.startIndex..<i]
          ownerIdentifier = String(data: ownerIdentifierData, encoding: .utf8)
          privateData = frameData[(i + 1)..<frameData.endIndex]
          break
        }
      }
      if let ownerIdentifier = ownerIdentifier, let privateData = privateData {
        print("\(frameHeader.id) -- \(ownerIdentifier) -- private data count: \(privateData.count)")
      } else {
        fatalError()
        break
      }

    case "UFID":
      var ownerIdentifier: String? = nil
      var fileIdentifierData: Data? = nil
      for i in frameData.startIndex..<frameData.endIndex {
        if frameData[i] == 0 {
          let ownerIdentifierData = frameData[frameData.startIndex..<i]
          ownerIdentifier = String(data: ownerIdentifierData, encoding: .utf8)
          fileIdentifierData = frameData[(i + 1)..<frameData.endIndex]
          break
        }
      }
      if let ownerIdentifier = ownerIdentifier, let fileIdentifierData = fileIdentifierData {
        print("\(frameHeader.id) -- \(ownerIdentifier) -- file identifier data count: \(fileIdentifierData.count)")
      } else {
        fatalError()
        break
      }
      
    default:
      print("Unsupported frame header ID: \(frameHeader.id)")
    }
    
    offset += frameHeader.dataSize
  }
  
  return metadata
}

func ID3v2Parser(_ data: Data) -> Metadata? {
  guard let header = parseID3v2Header(data) else {
    return nil
  }
  
  print("Header \(header)")
  
  if header.hasExtendedHeader {
    if let extendedHeader = parseID3v2ExtendedHeader(data) {
      print("Extended Header \(extendedHeader)")
      return parseID3v2Data(
        data: data.subdata(
          in: ID3v2_HEADER_SIZE..<(header.size - extendedHeader.size)
        ),
        version: header.version
      )
    }
  }
  
  return parseID3v2Data(
    data: data.subdata(in: ID3v2_HEADER_SIZE..<header.size),
    version: header.version
  )
}
