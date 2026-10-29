import Foundation
import OSLog
import TideCore
import UIKit
import Vision

/// Vision の汎用画像分類で魚種候補3つを出す（M2）。M5 で自前 Core ML に置換。
enum FishClassifier {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Classifier")

    /// 画像データ → 候補3つ。失敗時は既定候補。
    static func classify(_ data: Data) async -> [VisionMapping.Candidate] {
        let observations = await Task.detached(priority: .userInitiated) { () -> [VisionMapping.Observation] in
            guard let image = UIImage(data: data), let cgImage = image.cgImage else { return [] }
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: Self.orientation(image.imageOrientation))
            do {
                try handler.perform([request])
            } catch {
                return []
            }
            let results = request.results ?? []
            return results.prefix(40).map { VisionMapping.Observation(identifier: $0.identifier, confidence: Double($0.confidence)) }
        }.value
        if observations.isEmpty {
            logger.notice("分類結果なし。既定候補を使用")
        }
        return VisionMapping.candidates(from: observations)
    }

    private static func orientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
