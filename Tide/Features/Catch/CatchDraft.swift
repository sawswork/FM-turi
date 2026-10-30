import Foundation
import Observation
import TideCore
import UIKit

/// Catch 画面の入力状態。
@MainActor
@Observable
final class CatchDraft {
    var image: UIImage?
    var imageData: Data?
    var metadata: PhotoStore.Metadata?
    /// 撮影時刻（EXIF）か現在
    var capturedAt = Date()
    var photoLocation: GeoPoint?
    /// 魚種候補（写真を選ぶまでの仮置き: 形の違う3種）
    static let placeholderCandidates: [Species] = ["kasago", "ainame", "kijihata"].compactMap(Species.find)
    var candidates: [Species] = CatchDraft.placeholderCandidates
    var candidateConfidences: [Double] = []
    var selectedIndex = 0
    var lengthText = ""
    /// 推定に使った基準物（nil=ユーザー入力）
    var lengthSource: SizeEstimate.Reference.Kind?
    var sinkerLabel = "10"
    var hookLabel = "1/0"

    var sinkerGrams: Int { Int(sinkerLabel) ?? 0 }

    var selectedSpecies: Species? {
        candidates.indices.contains(selectedIndex) ? candidates[selectedIndex] : nil
    }

    var lengthCm: Double? {
        Double(lengthText.replacingOccurrences(of: ",", with: "."))
    }

    /// 確定候補の確度（Vision 前は nil）
    var confidence: Double? {
        candidateConfidences.indices.contains(selectedIndex) ? candidateConfidences[selectedIndex] : nil
    }

    var isClassifying = false

    func setPhoto(data: Data, now: Date = Date()) {
        imageData = data
        image = UIImage(data: data)
        let meta = PhotoStore.metadata(of: data)
        metadata = meta
        capturedAt = meta.capturedAt ?? now
        photoLocation = meta.location
    }

    /// Vision で候補3つを出し、1つ目を選択する。続けてサイズ推定（推定できなければ空のまま）。
    func classify() async {
        guard let imageData else { return }
        isClassifying = true
        let result = await FishClassifier.classify(imageData)
        candidates = result.map(\.species)
        candidateConfidences = result.map(\.confidence)
        selectedIndex = 0
        if lengthText.isEmpty, let estimate = await SizeEstimator.estimate(imageData) {
            lengthText = String(format: "%.0f", estimate.lengthCm)
            lengthSource = estimate.referenceKind
        }
        isClassifying = false
    }

    func reset() {
        image = nil
        imageData = nil
        metadata = nil
        capturedAt = Date()
        photoLocation = nil
        candidates = Self.placeholderCandidates
        candidateConfidences = []
        selectedIndex = 0
        lengthText = ""
        lengthSource = nil
    }
}
