import SwiftUI
import TideCore

/// 付録A A-7 のレイアウト確認ページ（アプリ内プレビュー専用）。実物は TideWidgets 拡張。
struct WidgetsPreviewView: View {
    var snapshot: WidgetSnapshot = .placeholder
    var now = Date()

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Wdg.pageGap) {
                    HStack(spacing: Wdg.pageGap) {
                        card(height: Wdg.smallHeight) { WidgetScoreSmallView(snapshot: snapshot, now: now) }
                        card(height: Wdg.smallHeight) { WidgetHoursSmallView(snapshot: snapshot, now: now) }
                    }
                    card(height: Wdg.mediumHeight) { WidgetMediumView(snapshot: snapshot, now: now) }
                    card(height: Wdg.largeHeight) { WidgetLargeView(snapshot: snapshot, now: now) }
                }
                .padding(.top, Wdg.pagePadTop)
                .padding(.horizontal, Wdg.pagePadHorizontal)
            }
        }
    }

    private func card<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(DesignTokens.Colors.surface, in: RoundedRectangle(cornerRadius: Wdg.cornerRadius, style: .continuous))
    }
}

#Preview {
    WidgetsPreviewView()
}
