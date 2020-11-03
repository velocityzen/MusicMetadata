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
    
    //TODO: check frameHeader.id
    
    offset += frameHeaderSize
    let textEncoding = getTextEncoding(data[offset])
    var information = data[(offset + 1)..<offset + frameHeader.dataSize]
    
    if version == 3 || version == 4 {
      if frameHeader.flags?.formatUnsynchronisation ?? false {
        information = removeUnsyncBytes(information)
      }
      
      if frameHeader.flags?.formatDataLengthIndicator ?? false {
        information = information[4..<information.count]
      }
    }

    let frameIdCase = frameHeader.id != "TXXX" && frameHeader.id.first == "T" ? "T*" : frameHeader.id

//    switch frameHeader.id {
//    case "TALB":
//      let text = String(data: information, encoding: textEncoding)
//      print("TALB -- Album/Movie/Show title -- \(text ?? "nil")")
//    default:
//      print("Unsupported frame header ID: \(frameHeader.id)")
//    }

    switch frameIdCase {
    case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST" :
      guard let text = String(data: information, encoding: textEncoding) else {
        break
      }
      print("\(frameHeader.id) -- \(text)")
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
