import Foundation
import SwiftData

/// タックル在庫（シンカー g / フック #）。付録A A-6・A-7 の初期値を seed する。
@Model
final class TackleItem {
    enum Kind: String, Codable {
        case sinker, hook
    }

    @Attribute(.unique) var key: String
    var kindRaw: String
    /// "5" "7" "10" "14" "21" / "#2" "#1" "1/0" "2/0"
    var label: String
    var sortOrder: Int
    var stock: Int
    /// 使用回数（L14）
    var usedCount: Int
    /// 現在選択中（Catch のタックルピルに出す）
    var isSelected: Bool

    init(kind: Kind, label: String, sortOrder: Int, stock: Int, isSelected: Bool = false) {
        self.key = "\(kind.rawValue):\(label)"
        self.kindRaw = kind.rawValue
        self.label = label
        self.sortOrder = sortOrder
        self.stock = stock
        self.usedCount = 0
        self.isSelected = isSelected
    }

    var kind: Kind { Kind(rawValue: kindRaw) ?? .sinker }

    /// シンカーの重さ g（フックは nil）
    var grams: Int? { kind == .sinker ? Int(label) : nil }

    static let sinkerLabels = ["5", "7", "10", "14", "21"]
    static let sinkerInitialStock = [12, 8, 6, 4, 2]
    static let hookLabels = ["#2", "#1", "1/0", "2/0"]
    static let hookInitialStock = [10, 14, 9, 5]

    /// 付録A の初期在庫。選択中は シンカー 10g / フック 1/0。
    static func seedItems() -> [TackleItem] {
        var items: [TackleItem] = []
        for (index, label) in sinkerLabels.enumerated() {
            items.append(TackleItem(kind: .sinker, label: label, sortOrder: index,
                                    stock: sinkerInitialStock[index], isSelected: label == "10"))
        }
        for (index, label) in hookLabels.enumerated() {
            items.append(TackleItem(kind: .hook, label: label, sortOrder: index,
                                    stock: hookInitialStock[index], isSelected: label == "1/0"))
        }
        return items
    }
}
