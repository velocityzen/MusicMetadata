func getTextEncoding(_ str: UInt8) -> String.Encoding {
  switch str {
    case 0x00:
      return .isoLatin1
    
    case 0x01:
      return .utf16LittleEndian
    
    case 0x02:
      return .utf16BigEndian
    
    case 0x03:
      return .utf8
    
    default:
      return .utf8
  }
}
