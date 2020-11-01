import Foundation
import FileType

typealias Parser = (_ data: Data) -> Metadata?

func getParser(for type: FileTypeExtension) -> Parser? {
  switch type {
    case .mp3:
      return ID3v2Parser
    default:
      return nil
  }
}
