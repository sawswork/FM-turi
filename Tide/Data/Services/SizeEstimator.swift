import Foundation
import OSLog
import TideCore
import UIKit
import Vision

/// 写真から魚の体長を推定（基準物=500円硬貨 or メジャー）。推定できなければ nil → ユーザー入力。
enum SizeEstimator {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Size")

    struct Result: Sendable {
        var lengthCm: Double
        var referenceKind: SizeEstimate.Reference.Kind
    }

    static func estimate(_ data: Data) async -> Result? {
        await Task.detached(priority: .userInitiated) { () -> Result? in
            guard let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }
            let width = Double(cgImage.width)
            let height = Double(cgImage.height)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            // 1) 顕著領域から魚（最大の矩形）と小さな正方形の物体（硬貨）を探す
            let objectness = VNGenerateObjectnessBasedSaliencyImageRequest()
            let rectangles = VNDetectRectanglesRequest()
            rectangles.maximumObservations = 8
            rectangles.minimumSize = 0.02
            rectangles.minimumAspectRatio = 0.7
            do {
                try handler.perform([objectness, rectangles])
            } catch {
                return nil
            }
            let salient = (objectness.results?.first?.salientObjects ?? []).map(\.boundingBox)
            guard let fishBox = salient.max(by: { $0.width * $0.height < $1.width * $1.height }) else { return nil }
            let fishPixels = Double(max(fishBox.width * width, fishBox.height * height))
            // 硬貨候補: 魚より十分小さい、ほぼ正方形の矩形
            let coinBoxes = (rectangles.results ?? [])
                .map(\.boundingBox)
                .filter { $0.width * $0.height < fishBox.width * fishBox.height * 0.2 }
            for box in coinBoxes.sorted(by: { $0.width * $0.height > $1.width * $1.height }) {
                if let reference = SizeEstimate.coinReference(boxWidth: box.width, boxHeight: box.height,
                                                              imageWidth: width, imageHeight: height),
                   let cm = SizeEstimate.lengthCm(fishPixelLength: fishPixels, reference: reference) {
                    return Result(lengthCm: cm, referenceKind: .coin)
                }
            }
            return nil
        }.value
    }
}
