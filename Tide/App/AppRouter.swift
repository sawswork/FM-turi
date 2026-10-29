import Observation
import TideCore

/// タブと画面遷移の状態。Catch 保存→図鑑、ディープリンクなどで使う。
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home

    func handle(_ link: DeepLink) {
        selectedTab = AppTab(deepLink: link)
    }
}
