import Foundation

extension Array {
  /// Splits an array into chunks of 2 items. If the number of items in the array is odd, the incomplete chunk (the last chunk) is discarded.
  func toPairs() -> [(Element, Element)] {
    return stride(from: 0, to: self.count, by: 2).compactMap { (firstIdx: Int) -> (Element, Element)? in
      let secondIdx = firstIdx + 1
      guard secondIdx < self.count else { return nil }
      return (self[firstIdx], self[secondIdx])
    }
  }
  
  /// Returns nil instead of crashing in case of out-of-bounds array access
  public subscript(safeIndex index: Int) -> Element? {
      guard index >= 0, index < endIndex else {
          return nil
      }

      return self[index]
  }
}
