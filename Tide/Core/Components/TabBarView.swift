import SwiftUI

/// タブバー: margin=0 20 22 20、h68 r34 bg 面 pad=0 8、5項目等間隔。
/// 各48×52 アイコン24。中央 camera だけ 54×54 円 bg橙 アイコン黒。
struct TabBarView: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selected = tab
                } label: {
                    item(for: tab)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DesignTokens.TabBar.padHorizontal)
        .frame(height: DesignTokens.TabBar.height)
        .background(
            DesignTokens.Colors.surface,
            in: RoundedRectangle(cornerRadius: DesignTokens.TabBar.radius, style: .continuous)
        )
        .padding(.horizontal, DesignTokens.TabBar.marginHorizontal)
        .padding(.bottom, DesignTokens.TabBar.marginBottom)
    }

    @ViewBuilder
    private func item(for tab: AppTab) -> some View {
        if tab == .catchFish {
            Circle()
                .fill(DesignTokens.Colors.orange)
                .frame(width: DesignTokens.TabBar.cameraSize, height: DesignTokens.TabBar.cameraSize)
                .overlay {
                    IconView(icon: tab.icon,
                             size: DesignTokens.TabBar.iconSize,
                             color: DesignTokens.Colors.black)
                }
        } else {
            IconView(icon: tab.icon,
                     size: DesignTokens.TabBar.iconSize,
                     color: selected == tab ? DesignTokens.Colors.primary : DesignTokens.Colors.secondary)
                .frame(width: DesignTokens.TabBar.itemWidth, height: DesignTokens.TabBar.itemHeight)
        }
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .home
    ZStack(alignment: .bottom) {
        DesignTokens.Colors.background.ignoresSafeArea()
        TabBarView(selected: $tab)
    }
}
