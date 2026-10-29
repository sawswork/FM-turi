import CoreML
import Foundation
import OSLog
import TideCore
import UIKit
import Vision

/// 魚種候補3つ。同梱の自前 Core ML（FishClassifier.mlmodelc、M5）があればそれを使い、
/// 無ければ Vision の汎用画像分類＋付録B へのマッピング（M2）。
enum FishClassifier {
    private static let logger = Logger(subsystem: "jp.tide.app", category: "Classifier")

    /// 同梱モデルの有無（確度表示の文言などに使う）。
    static var hasCustomModel: Bool {
        Bundle.main.url(forResource: "FishClassifier", withExtension: "mlmodelc") != nil
    }

    /// 画像データ → 候補3つ。失敗時は既定候補。
    static func classify(_ data: Data) async -> [VisionMapping.Candidate] {
        let custom = await Task.detached(priority: .userInitiated) { () -> [VisionMapping.Observation] in
            classifyWithCustomModel(data)
        }.value
        if !custom.isEmpty {
            return customCandidates(from: custom)
        }
        let observations = await Task.detached(priority: .userInitiated) { () -> [VisionMapping.Observation] in
            classifyWithGenericModel(data)
        }.value
        if observations.isEmpty {
            logger.notice("分類結果なし。既定候補を使用")
        }
        return VisionMapping.candidates(from: observations)
    }

    /// 自前モデルの出力（識別子 = 付録B の id、確度 = softmax）→ 候補3つ。
    static func customCandidates(from observations: [VisionMapping.Observation]) -> [VisionMapping.Candidate] {
        var result = observations
            .compactMap { obs in Species.find(obs.identifier).map { VisionMapping.Candidate(species: $0, confidence: min(max(obs.confidence, 0), 1)) } }
            .sorted { $0.confidence > $1.confidence }
        result = Array(result.prefix(3))
        for fallback in VisionMapping.defaultCandidates where result.count < 3 && !result.contains(where: { $0.id == fallback.id }) {
            result.append(fallback)
        }
        return result
    }

    private nonisolated static func classifyWithCustomModel(_ data: Data) -> [VisionMapping.Observation] {
        guard let url = Bundle.main.url(forResource: "FishClassifier", withExtension: "mlmodelc"),
              let image = UIImage(data: data), let cgImage = image.cgImage else { return [] }
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let model = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: config))
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation(image.imageOrientation))
            try handler.perform([request])
            let results = request.results as? [VNClassificationObservation] ?? []
            return results.map { VisionMapping.Observation(identifier: $0.identifier, confidence: Double($0.confidence)) }
        } catch {
            return []
        }
    }

    private nonisolated static func classifyWithGenericModel(_ data: Data) -> [VisionMapping.Observation] {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else { return [] }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation(image.imageOrientation))
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let results = request.results ?? []
        return results.prefix(40).map { VisionMapping.Observation(identifier: $0.identifier, confidence: Double($0.confidence)) }
    }

    private nonisolated static func orientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
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
