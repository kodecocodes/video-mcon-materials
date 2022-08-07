/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Cocoa
import Vapor

extension String: LocalizedError {
  public var errorDescription: String? {
    return self
  }
}

struct DownloadFile: Codable {
  init(nr: Int, type: String) {
    name = "graphics-project-ver-\(nr).\(type)"
    size = SuperStorage.imageFileSize(type: type)
    date = Date().addingTimeInterval(TimeInterval(nr*27*60*60 - 30*24*60*60))
  }
  
  let name: String
  let size: Int
  let date: Date
}

extension NSImage {
  convenience init?(gradientColors: [NSColor], imageSize: NSSize, includeDate: Bool = true) {
    guard let gradient = NSGradient(colors: gradientColors) else { return nil }
    let rect = NSRect(origin: CGPoint.zero, size: imageSize)
    self.init(size: rect.size)
    let path = NSBezierPath(rect: rect)
    self.lockFocus()
    gradient.draw(in: path, angle: 0.0)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    if includeDate {
      NSString(string: formatter.string(from: Date())).draw(at: .zero, withAttributes: [
        NSAttributedString.Key.font: NSFont.systemFont(ofSize: 48),
        NSAttributedString.Key.foregroundColor: NSColor.white
      ])
    }
    self.unlockFocus()
  }
}

struct SuperStorage {
  static func imageURL(type: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory().appending("concurrency-book-image.\(type)"))
  }
  
  static func imageFileSize(type: String) -> Int {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL(type: type).path),
          let size = attributes[FileAttributeKey.size] as? Int else { return 0 }
    return size
  }
  
  static let files = (1...3).flatMap { [DownloadFile(nr: $0, type: "tiff"), DownloadFile(nr: $0, type: "jpeg")] }
  
  static func routes(_ app: Application) throws {
    /// Create a tiff version
    guard let image = NSImage(gradientColors: [.magenta, .cyan, .purple], imageSize: .init(width: 800, height: 1200)),
          let tiffData = image.tiffRepresentation else {
            throw "Couldn't create a test tiff image."
          }
    try tiffData.write(to: imageURL(type: "tiff"))

    /// Create a jpeg version
    guard let image = NSImage(gradientColors: [.magenta, .cyan, .purple], imageSize: .init(width: 2000, height: 3000)),
          let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
          let jpegData = bitmap.representation(using: .jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]) else {
            throw "Couldn't create a test jpeg image."
          }
    try jpegData.write(to: imageURL(type: "jpeg"))

    // Routes
    app.get("files", "list") { req -> Response in
      let responseData = try! JSONEncoder().encode(files)
      return Response(body: .init(data: responseData))
    }
    
    app.get("files", "status") { req -> Response in
      return Response(body: .init(string: "Using \((1...80).randomElement()!)% of available space, \((1...900).randomElement()!) duplicate files."))
    }
    
    app.get("files", "download") { req -> Response in
      // Validate file name
      guard let name = try? req.query.decode(String.self),
            let file = files.first(where: { $0.name == name }),
            let ext = file.name.components(separatedBy: ".").last,
            let data = try? Data(contentsOf: imageURL(type: ext)) else {
              let responseData = try! JSONSerialization.data(withJSONObject: ["error": "File not found."], options: .prettyPrinted)
              return Response(body: .init(data: responseData))
            }

      // Return a partial response
      if req.headers.range?.unit == .bytes,
         let firstRange = req.headers.range?.ranges.first,
         case HTTPHeaders.Range.Value.within(let start, let end) = firstRange {
        
        let dataChunk = data[start...end]
        let response = Response(body: .init(data: dataChunk))
        response.status = .partialContent
        response.headers.add(name: .contentLength, value: "\(end - start + 1)")
        response.headers.add(name: .contentRange, value: "bytes \(start)-\(end)/\(imageFileSize(type: ext))")
        response.headers.add(name: .contentDisposition, value: "filename=\"\(file.name)\"")
        return response
      }
      
      // This code intentionally slows down serving the file
      // so that the reader can play through different scenarios with
      // cancelling the download.
      let chunk = 1_000_000
      var currentOffset = 0
      
      let response = Response(body: .init(stream: { writer in
        req.eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .seconds(1)) { task in
          let endIndex = min(currentOffset+chunk, data.count)
          writer.write(.buffer(.init(data: data[currentOffset..<endIndex])), promise: nil)
          if endIndex == data.count {
            writer.write(.end, promise: nil)
            task.cancel(promise: nil)
          }
          currentOffset += chunk
        }
      }))
      response.headers.add(name: .contentType, value: "application/octet-stream")
      return response
    }
  }
}
