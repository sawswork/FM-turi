import OSLog
import SwiftUI
import TideCore

/// 5タブのルート。タブバーは付録A A-0 のカスタム実装。
struct RootView: View {
    @State private var selectedTab: AppTab = .home
    private let logger = Logger(subsystem: "jp.tide.app", category: "RootView")

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView(selected: $selectedTab)
        }
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else {
                logger.notice("未対応のURL: \(url.absoluteString, privacy: .public)")
                return
            }
            selectedTab = AppTab(deepLink: link)
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch selectedTab {
        case .home: HomeView()
        case .spots: SpotsView()
        case .catchFish: CatchView()
        case .zukan: ZukanView()
        case .tackle: TackleView()
        }
    }
}

#Preview {
    RootView()
}
