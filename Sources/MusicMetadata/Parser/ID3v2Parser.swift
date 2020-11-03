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

    switch frameIdCase {
    
    case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST" :
      guard let text = String(data: information, encoding: textEncoding) else {
        fatalError()
        break
      }
      print("\(frameHeader.id) -- \(text)")
      
    case "TXXX":
      let dataArray = information.split(separator: 0)
      guard dataArray.count == 2,
            let description = String(data: dataArray[0], encoding: textEncoding),
            let value = String(data: dataArray[1], encoding: textEncoding)
      else {
        fatalError()
        break
      }
      print("\(frameHeader.id) -- \(description) -- \(value)")
      
    case "APIC":
      var mimeType: String? = nil
      var pictureType: UInt8? = nil
      var description: String? = nil
      var pictureData: Data? = nil
      var elementIndex = 0
      var previousDataLastByte = 0
      for i in information.startIndex..<information.endIndex {
        if information[i] == 0 {
          switch elementIndex {
          case 0:
            let mimeTypeData = information[information.startIndex..<i]
            mimeType = String(data: mimeTypeData, encoding: .utf8)
            pictureType = information[(i + 1)]
            elementIndex += 1
            previousDataLastByte = i + 1
          case 1:
            let descriptionData = information[(previousDataLastByte + 1)..<i]
            description = String(data: descriptionData, encoding: textEncoding)
            elementIndex += 1
            previousDataLastByte = i - 1
          case 2:
            pictureData = information[(previousDataLastByte + 1)..<information.endIndex]
            break
          default:
            break
          }
        }
      }
      if let mimeType = mimeType, let pictureType = pictureType, let description = description, let pictureData = pictureData {
        print("\(frameHeader.id) -- \(mimeType) -- \(pictureType) -- \(description)")
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
