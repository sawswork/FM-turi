import Foundation
import ImageIO
import OSLog
import TideCore
import UIKit

/// 釣果写真の保存（Application Support/Photos、長辺1024の JPEG）と EXIF 読み出し。
enum PhotoStore {
    static let maxLongEdge: CGFloat = 1024
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Photo")

    struct Metadata: Sendable {
        var capturedAt: Date?
        var location: GeoPoint?
        var pixelWidth: Double
        var pixelHeight: Double
    }

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    /// 元データの EXIF（撮影時刻・GPS・画素数）。
    static func metadata(of data: Data) -> Metadata {
        var meta = Metadata(capturedAt: nil, location: nil, pixelWidth: 0, pixelHeight: 0)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return meta
        }
        meta.pixelWidth = (props[kCGImagePropertyPixelWidth as String] as? Double) ?? 0
        meta.pixelHeight = (props[kCGImagePropertyPixelHeight as String] as? Double) ?? 0
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            meta.capturedAt = Exif.date(from: exif[kCGImagePropertyExifDateTimeOriginal as String] as? String)
        }
        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            meta.location = Exif.coordinate(
                latitude: gps[kCGImagePropertyGPSLatitude as String] as? Double,
                latitudeRef: gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
                longitude: gps[kCGImagePropertyGPSLongitude as String] as? Double,
                longitudeRef: gps[kCGImagePropertyGPSLongitudeRef as String] as? String
            )
        }
        return meta
    }

    /// 長辺 1024 に縮小（向きは正立に焼き込む）。
    static func downscale(_ image: UIImage) -> UIImage {
        let size = Exif.scaledSize(width: image.size.width, height: image.size.height, maxLongEdge: maxLongEdge)
        let target = CGSize(width: size.width, height: size.height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// 縮小して保存し、ファイル名を返す。
    static func save(_ image: UIImage, id: UUID = UUID()) -> (fileName: String, size: CGSize)? {
        let scaled = downscale(image)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        let name = "\(id.uuidString).jpg"
        do {
            try data.write(to: url(for: name), options: .atomic)
            return (name, scaled.size)
        } catch {
            logger.error("写真の保存に失敗: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func load(_ fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        return UIImage(contentsOfFile: url(for: fileName).path)
    }

    static func delete(_ fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
