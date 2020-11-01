import Foundation
import FileType

private func parse(for filetype: FileType, data: Data) throws -> Metadata? {
  guard let parser = getParser(for: filetype.type) else {
    return nil
  }
  
  guard var metadata = parser(data) else {
    return nil
  }
  
  metadata.type = filetype.type
  metadata.mime = filetype.mime
  metadata.ext = filetype.ext
  return metadata
}

public func getMusicMetadata(for data: Data) throws -> Metadata?  {
  let fileType = FileType.getFor(data: data)!
  return try parse(for: fileType, data: data)
}

public func getMusicMetadata(for file: URL) throws -> Metadata?  {
  let data = try Data(contentsOf: file, options: .mappedIfSafe)
  return try getMusicMetadata(for: data)
}
