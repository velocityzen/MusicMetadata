import Foundation

internal extension Data {
  func getInt16LE(offset: Int = 0) -> Int {
    return Int(
      UInt16(self[offset]) |
        (UInt16(self[offset + 1]) << 8)
    )
  }
  
  func getInt16BE(offset: Int = 0) -> Int {
    return Int(
      UInt16(self[offset]) << 8 |
        UInt16(self[offset + 1])
    )
  }
  
  func getInt24LE(offset: Int = 0) -> Int {
    return Int(
      UInt32(self[offset]) |
      (UInt32(self[offset + 1]) << 8) |
      (UInt32(self[offset + 2]) << 16)
    )
  }
  
  func getInt24BE(offset: Int = 0) -> Int {
    return Int(
      (UInt32(self[offset]) << 16) |
      (UInt32(self[offset + 1]) << 8) |
      (UInt32(self[offset + 2]))
    )
  }
  
  func getInt32LE(offset: Int = 0) -> Int {
    return Int(
      (
        UInt32(self[offset]) |
          (UInt32(self[offset + 1]) << 8) |
          (UInt32(self[offset + 2]) << 16) |
          (UInt32(self[offset + 3]) << 24)
      )
    )
  }
    
  func getInt32BE(offset: Int = 0) -> Int {
    return Int(
      (UInt32(self[offset]) << 24) |
      (UInt32(self[offset + 1]) << 16) |
      (UInt32(self[offset + 2]) << 8) |
      UInt32(self[offset + 3])
    )
  }
  
  func readUInt32BE(offset: Int = 0) -> Int? {
    guard offset >= self.startIndex && offset + 4 < self.endIndex else {
      return nil
    }
    return Int(
      (UInt32(self[offset]) << 24) |
      (UInt32(self[offset + 1]) << 16) |
      (UInt32(self[offset + 2]) << 8) |
      UInt32(self[offset + 3])
    )
  }
    
  func getUInt32SyncSafe(offset: Int = 0) -> Int {
    return Int(
      UInt32(self[offset + 3]) & 0x7F |
      UInt32(self[offset + 2]) << 7 |
      UInt32(self[offset + 1]) << 14 |
      UInt32(self[offset]) << 21
    )
  }
  
  func getBit(offset: Int = 0, bit: UInt8) -> Bool {
    return (self[offset] & (1 << bit)) != 0;
  }
}
