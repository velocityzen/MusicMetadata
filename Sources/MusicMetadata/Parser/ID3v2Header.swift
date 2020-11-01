import Foundation

let ID3v2_HEADER_SIZE = 10

struct ID3v2Header {
  let fileIdentifier: String
  let version: UInt8
  let revision: UInt8
  let hasUnsynchronisation: Bool
  let hasExtendedHeader: Bool
  let isExperimental: Bool
  let hasFooter: Bool
  let size: Int
}

func parseID3v2Header(_ data: Data) -> ID3v2Header? {
  guard let fileIdentifier = data.getString(from: 0..<3, encoding: .ascii) else {
    return nil
  }
  
  if fileIdentifier != "ID3" {
    return nil
  }
  
  return ID3v2Header(
    fileIdentifier: fileIdentifier,
    version: data[3],
    revision: data[4],
    hasUnsynchronisation: data.getBit(offset: 5, bit: 7),
    hasExtendedHeader: data.getBit(offset: 5, bit: 6),
    isExperimental: data.getBit(offset: 5, bit: 5),
    hasFooter: data.getBit(offset: 5, bit: 4),
    size: data.getUInt32SyncSafe(offset: 6)
  )
}

struct ID3v2ExtendedHeader {
  let size: Int
  let flags: Int
  let padding: Int
  let hasCRCData: Bool
}

func parseID3v2ExtendedHeader(_ data: Data) -> ID3v2ExtendedHeader? {
  return ID3v2ExtendedHeader(
    size: data.getInt32BE(),
    flags: data.getInt16BE(offset: 4),
    padding: data.getInt32BE(offset: 6),
    hasCRCData: data.getBit(offset: 4, bit: 31)
  )
}
