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
    /// 魚種候補（L7 で Vision、L6 は付録B の先頭3種）
    var candidates: [Species] = Array(Species.all.prefix(3))
    var candidateConfidences: [Double] = []
    var selectedIndex = 0
    var lengthText = ""
    var sinkerGrams = 10
    var hookSize = "1/0"

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

    func setPhoto(data: Data, now: Date = Date()) {
        imageData = data
        image = UIImage(data: data)
        let meta = PhotoStore.metadata(of: data)
        metadata = meta
        capturedAt = meta.capturedAt ?? now
        photoLocation = meta.location
    }

    func reset() {
        image = nil
        imageData = nil
        metadata = nil
        capturedAt = Date()
        photoLocation = nil
        candidates = Array(Species.all.prefix(3))
        candidateConfidences = []
        selectedIndex = 0
        lengthText = ""
    }
}
