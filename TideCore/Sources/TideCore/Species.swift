import Foundation

/// 魚のシルエットの形（図鑑のカード用）。
public enum FishShapeKind: String, Codable, Sendable, CaseIterable {
    case rock, long, flat, deep
}

/// 適水温帯（°C）。
public struct TemperatureBand: Hashable, Codable, Sendable {
    public var low: Double
    public var high: Double

    public init(low: Double, high: Double) {
        self.low = low
        self.high = high
    }

    public var center: Double { (low + high) / 2 }
    public var halfWidth: Double { (high - low) / 2 }
}

/// 付録B 魚種マスタ。
public struct Species: Hashable, Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var shape: FishShapeKind
    /// nil = 適水温の指定なし（その他）
    public var band: TemperatureBand?
    public var note: String

    public init(id: String, name: String, shape: FishShapeKind, band: TemperatureBand?, note: String) {
        self.id = id
        self.name = name
        self.shape = shape
        self.band = band
        self.note = note
    }

    public static let all: [Species] = [
        Species(id: "kasago", name: "カサゴ", shape: .rock, band: TemperatureBand(low: 12, high: 22), note: "通年"),
        Species(id: "murasoi", name: "ムラソイ", shape: .rock, band: TemperatureBand(low: 10, high: 20), note: "冬～春"),
        Species(id: "kurosoi", name: "クロソイ", shape: .rock, band: TemperatureBand(low: 8, high: 18), note: "冬～春、夜"),
        Species(id: "ainame", name: "アイナメ", shape: .long, band: TemperatureBand(low: 8, high: 18), note: "秋～冬"),
        Species(id: "kijihata", name: "キジハタ", shape: .deep, band: TemperatureBand(low: 18, high: 26), note: "夏～秋"),
        Species(id: "oomonhata", name: "オオモンハタ", shape: .deep, band: TemperatureBand(low: 18, high: 27), note: "夏～秋"),
        Species(id: "akahata", name: "アカハタ", shape: .deep, band: TemperatureBand(low: 18, high: 26), note: "夏～秋"),
        Species(id: "takenoko", name: "タケノコメバル", shape: .rock, band: TemperatureBand(low: 10, high: 20), note: "春・秋"),
        Species(id: "mebaru", name: "メバル", shape: .rock, band: TemperatureBand(low: 10, high: 18), note: "冬～春、夜"),
        Species(id: "bekkouzoi", name: "ベッコウゾイ", shape: .rock, band: TemperatureBand(low: 8, high: 16), note: "冬"),
        Species(id: "hata_other", name: "ハタ類（未分類）", shape: .deep, band: TemperatureBand(low: 16, high: 26),
                note: "候補に出す用"),
        Species(id: "other", name: "その他", shape: .long, band: nil, note: "ユーザー入力")
    ]

    public static func find(_ id: String) -> Species? {
        all.first { $0.id == id }
    }

    /// 釣れ率の既定の対象（通年のカサゴ）。
    public static let defaultForScore = all[0]
}
