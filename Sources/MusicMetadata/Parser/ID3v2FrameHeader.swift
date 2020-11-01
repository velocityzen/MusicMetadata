import Foundation

struct ID3v2FrameHeaderFlags {
  let statusTagAlterPreservation: Bool
  let statusFileAlterPreservation: Bool
  let statusReadOnly: Bool
  let formatGroupingIdentity: Bool
  let formatCompression: Bool
  let formatEncryption: Bool
  let formatUnsynchronisation: Bool
  let formatDataLengthIndicator: Bool
}

struct ID3v2FrameHeader {
  let id: String
  let size: Int
  var flags: ID3v2FrameHeaderFlags?
}

func parseID3v2FrameHeaderFlags(_ data: Data) -> ID3v2FrameHeaderFlags {
  return ID3v2FrameHeaderFlags(
    statusTagAlterPreservation: data.getBit(offset: 8, bit: 6),
    statusFileAlterPreservation: data.getBit(offset: 8, bit: 5),
    statusReadOnly: data.getBit(offset: 8, bit: 4),
    formatGroupingIdentity: data.getBit(offset: 9, bit: 7),
    formatCompression: data.getBit(offset: 9, bit: 3),
    formatEncryption: data.getBit(offset: 9, bit: 2),
    formatUnsynchronisation: data.getBit(offset: 9, bit: 1),
    formatDataLengthIndicator: data.getBit(offset: 9, bit: 0)
  )
}

func getID3v2FrameHeaderSize(_ version: UInt8) -> Int? {
  switch (version) {
    case 2:
      return 6
    case 3, 4:
      return 10
    default:
      return nil
  }
}

func parseID3v2FrameHeader(data: Data, version: UInt8) -> ID3v2FrameHeader? {
  switch version {
    case 2:
      return ID3v2FrameHeader(
        id: data.getString(from: 0..<3, encoding: .ascii)!,
        size: data.getInt24BE(offset: 3)
      )
      
    case 3:
      return ID3v2FrameHeader(
        id: data.getString(from: 0..<4, encoding: .ascii)!,
        size: data.getInt32BE(offset: 4),
        flags: parseID3v2FrameHeaderFlags(data)
      )
      
    case 4:
      return ID3v2FrameHeader(
        id: data.getString(from: 0..<4, encoding: .ascii)!,
        size: data.getUInt32SyncSafe(offset: 4),
        flags: parseID3v2FrameHeaderFlags(data)
      )
      
    default:
      return nil
  }
}
