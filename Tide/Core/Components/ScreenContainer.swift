import SwiftUI

/// 各画面の共通の器。背景黒、タブバー分の下余白。
struct ScreenContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .top) {
            DesignTokens.Colors.background.ignoresSafeArea()
            content
        }
        .safeAreaPadding(.bottom, DesignTokens.TabBar.occupiedHeight)
    }
}
