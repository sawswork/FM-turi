import SwiftUI

/// L2 の共通部品を1画面で確認するプレビュー専用ビュー（アプリからは使わない）。
struct ComponentsGallery: View {
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(spacing: 24) {
                TopBarView {
                    LocationPill(name: "城ヶ島 西側")
                } trailing: {
                    RoundButton(icon: .dots)
                }
                RingView(progress: 0.72, size: 240, radius: 102, lineWidth: 13, haloLineWidth: 28)
                HStack(spacing: 10) {
                    VStack(spacing: 12) {
                        IconView(icon: .wind)
                        MeterView(fraction: 0.60, color: DesignTokens.Colors.orange)
                    }
                    VStack(spacing: 12) {
                        IconView(icon: .wave)
                        MeterView(fraction: 0.22)
                    }
                    VStack(spacing: 12) {
                        IconView(icon: .drop)
                        MeterView(fraction: 0.80, color: DesignTokens.Colors.green)
                    }
                    VStack(spacing: 12) {
                        IconView(icon: .pressure)
                        MeterView(fraction: 0.45, color: DesignTokens.Colors.green)
                    }
                }
                HStack(spacing: 14) {
                    ForEach([0.0, 3.7, 7.4, 12.4, 14.8, 22.1], id: \.self) { age in
                        MoonGlyph(age: age)
                    }
                }
                Spacer()
            }
            TabBarView(selected: $tab)
        }
    }
}

#Preview {
    ComponentsGallery()
}
