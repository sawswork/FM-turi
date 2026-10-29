import Foundation

/// Vision の汎用分類（英語ラベル）→ 付録B の魚種候補へのマッピング（指示書 §4 M2）。
public enum VisionMapping {
    public struct Observation: Hashable, Sendable {
        public var identifier: String
        public var confidence: Double

        public init(identifier: String, confidence: Double) {
            self.identifier = identifier
            self.confidence = confidence
        }
    }

    public struct Candidate: Hashable, Sendable, Identifiable {
        public var species: Species
        /// 0...1
        public var confidence: Double
        public var id: String { species.id }

        public init(species: Species, confidence: Double) {
            self.species = species
            self.confidence = confidence
        }
    }

    /// ラベルに含まれる語 → 魚種 id と重み。
    static let rules: [(keywords: [String], species: [(String, Double)])] = [
        (["rockfish", "scorpionfish", "scorpion fish", "sculpin", "stonefish", "lionfish"],
         [("kasago", 1.0), ("murasoi", 0.7), ("takenoko", 0.6)]),
        (["grouper", "coral trout", "hind"], [("kijihata", 1.0), ("akahata", 0.8), ("oomonhata", 0.8)]),
        (["sea bass", "seabass", "bass", "perch"], [("hata_other", 0.9), ("kijihata", 0.6), ("mebaru", 0.5)]),
        (["snapper", "bream", "porgy", "red fish", "redfish"], [("akahata", 0.8), ("hata_other", 0.6), ("kasago", 0.4)]),
        (["greenling", "lingcod", "eel", "trout", "salmon", "pike", "barracuda"], [("ainame", 1.0), ("other", 0.3)]),
        (["flounder", "flatfish", "sole", "halibut", "ray", "skate"], [("other", 1.0)]),
        (["goldfish", "koi", "carp", "tuna", "mackerel", "sardine", "anchovy", "herring"], [("other", 0.8)]),
        (["fish", "seafood", "catch", "angling"], [("kasago", 0.5), ("mebaru", 0.4), ("hata_other", 0.4)])
    ]

    /// 既定候補（何も当たらないとき）。
    public static let defaultCandidates: [Candidate] = [
        Candidate(species: Species.find("kasago")!, confidence: 0),
        Candidate(species: Species.find("mebaru")!, confidence: 0),
        Candidate(species: Species.find("hata_other")!, confidence: 0)
    ]

    /// 上位3候補。確度は 0...1 に丸める。
    public static func candidates(from observations: [Observation], count: Int = 3) -> [Candidate] {
        var scores: [String: Double] = [:]
        for observation in observations where observation.confidence > 0.01 {
            let label = observation.identifier.lowercased().replacingOccurrences(of: "_", with: " ")
            for rule in rules where rule.keywords.contains(where: { label.contains($0) }) {
                for (id, weight) in rule.species {
                    scores[id, default: 0] += observation.confidence * weight
                }
            }
        }
        var ranked: [Candidate] = []
        for (id, score) in scores {
            guard let species = Species.find(id) else { continue }
            ranked.append(Candidate(species: species, confidence: min(score, 1)))
        }
        ranked.sort { lhs, rhs in
            if lhs.confidence == rhs.confidence { return lhs.species.id < rhs.species.id }
            return lhs.confidence > rhs.confidence
        }
        var result = Array(ranked.prefix(count))
        for fallback in defaultCandidates where result.count < count && !result.contains(where: { $0.id == fallback.id }) {
            result.append(fallback)
        }
        return result
    }
}
