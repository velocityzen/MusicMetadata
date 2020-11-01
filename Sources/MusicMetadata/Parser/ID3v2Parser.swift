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
    
    var frameData = data[offset..<offset + frameHeader.size]
    
    if version == 3 || version == 4 {
      if header.flags?.formatUnsynchronisation ?? false {
        frameData = removeUnsyncBytes(frameData)
      }
      
      if header.flags?.formatDataLengthIndicator ?? false {
        frameData = frameData[4..<frameData.count]
      }
    }
    
    let encoding = getTextEncoding(data[0])
    let frameIdCase = frameHeader.id != "TXXX" && frameHeader.id.first == "T" ? "T*" : frameHeader.id
    

    switch frameIdCase {
      case "T*", "IPLS", "MVIN", "MVNM", "PCS", "PCST" :
        guard let text = frameData.getString(from: 1..<data.count, encoding: encoding) else {
          return break
        }
        
        switch frameHeader.id {
          case "TMLC", "TIMPL", "IPLS":
      
    }
    
    
    offset += frameHeader.size
    
    print("\(frameHeader.id) = \(values)")
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
