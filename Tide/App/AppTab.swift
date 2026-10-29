import TideCore

/// タブバーの5項目（A-0 の順: home / pin / camera / book / hook）。
enum AppTab: Int, CaseIterable, Identifiable, Sendable {
    case home
    case spots
    case catchFish
    case zukan
    case tackle

    var id: Int { rawValue }

    /// UI テスト用の識別子
    var identifier: String {
        switch self {
        case .home: "home"
        case .spots: "spots"
        case .catchFish: "catch"
        case .zukan: "zukan"
        case .tackle: "tackle"
        }
    }

    var icon: TideIcon {
        switch self {
        case .home: .home
        case .spots: .pin
        case .catchFish: .camera
        case .zukan: .book
        case .tackle: .hook
        }
    }

    /// ディープリンクが指すタブ。
    init(deepLink: DeepLink) {
        switch deepLink {
        case .catchScreen: self = .catchFish
        case .home: self = .home
        case .zukan: self = .zukan
        case .tackle: self = .tackle
        }
    }
}
