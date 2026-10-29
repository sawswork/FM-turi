import SwiftUI

/// 上部帯: h72 pad=26 24 0 24。左右に部品を置く。
struct TopBarView<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            leading
            Spacer(minLength: 0)
            trailing
        }
        .padding(.top, DesignTokens.Screen.topBarPadTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        .frame(height: DesignTokens.Screen.topBarHeight, alignment: .top)
    }
}

#Preview {
    ZStack(alignment: .top) {
        DesignTokens.Colors.background.ignoresSafeArea()
        TopBarView {
            LocationPill(name: "城ヶ島 西側")
        } trailing: {
            RoundButton(icon: .dots)
        }
    }
}
