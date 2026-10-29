import OSLog
import SwiftUI
import TideCore

/// 5タブのルート。タブバーは付録A A-0 のカスタム実装。
struct RootView: View {
    @Environment(AppRouter.self) private var router
    @AppStorage(NoticeView.acceptedKey) private var noticeAccepted = false
    private let logger = Logger(subsystem: "jp.tide.app", category: "RootView")

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            screen(for: router.selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if router.selectedTab != .catchFish {
                TabBarView(selected: $router.selectedTab)
            }
        }
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else {
                logger.notice("未対応のURL: \(url.absoluteString, privacy: .public)")
                return
            }
            router.handle(link)
        }
        .fullScreenCover(isPresented: Binding(get: { !noticeAccepted }, set: { noticeAccepted = !$0 })) {
            NoticeView { noticeAccepted = true }
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
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
        .previewEnvironment()
}
