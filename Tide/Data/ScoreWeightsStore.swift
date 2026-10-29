import Foundation
import TideCore

/// 釣れ率 v2 の重みの保存（App Group の UserDefaults）。無ければ v1。
enum ScoreWeightsStore {
    static let key = "score.weights.v2"

    static var current: FishingScore.Weights {
        guard let data = WidgetBridge.defaults.data(forKey: key),
              let weights = try? JSONDecoder().decode(FishingScore.Weights.self, from: data) else { return .v1 }
        return weights
    }

    static func save(_ weights: FishingScore.Weights) {
        if let data = try? JSONEncoder().encode(weights) {
            WidgetBridge.defaults.set(data, forKey: key)
        }
    }

    static func reset() {
        WidgetBridge.defaults.removeObject(forKey: key)
    }
}
