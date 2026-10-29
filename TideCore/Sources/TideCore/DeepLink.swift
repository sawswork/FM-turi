import Foundation

/// アプリのディープリンク。`tide://catch` → `.catchScreen`、`tide://home` → `.home`。
public enum DeepLink: Equatable, Sendable {
    /// Catch 画面を開く（ウィジェットのカメラボタン）。
    case catchScreen
    /// Home を開く。
    case home

    public static let scheme = "tide"

    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        let host = url.host?.lowercased() ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let target = host.isEmpty ? path : host
        switch target {
        case "catch": self = .catchScreen
        case "home", "": self = .home
        default: return nil
        }
    }

    /// 自身を表す URL。
    public var url: URL {
        switch self {
        case .catchScreen: URL(string: "\(Self.scheme)://catch")!
        case .home: URL(string: "\(Self.scheme)://home")!
        }
    }
}
