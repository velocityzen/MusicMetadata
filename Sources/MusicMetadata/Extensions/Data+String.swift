import Foundation

internal extension Data {
  func getString(from range: Range<Int>, encoding: String.Encoding = .utf8) -> String? {
    guard range.endIndex <= self.count else {
      return nil
    }
    return String(data: self[range], encoding: encoding)
  }
}
