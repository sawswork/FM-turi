import SwiftUI

/// 丸ボタン: 既定 36×36 r18 bg 面、アイコン18 白 線幅2。
/// ウィジェット等で 38/44 も使うため size を可変にしている（既定値は A-0 の round36）。
struct RoundButton: View {
    let icon: TideIcon
    var size: CGFloat = DesignTokens.RoundButton.size
    var iconSize: CGFloat = DesignTokens.RoundButton.iconSize
    var lineWidth: CGFloat = DesignTokens.RoundButton.lineWidth
    var background: Color = DesignTokens.Colors.surface
    var foreground: Color = DesignTokens.Colors.primary
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(background)
                .frame(width: size, height: size)
                .overlay {
                    IconView(icon: icon, size: iconSize, lineWidth: lineWidth, color: foreground)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        HStack(spacing: 16) {
            RoundButton(icon: .dots)
            RoundButton(icon: .plus)
            RoundButton(icon: .chevronLeft)
            RoundButton(icon: .book, size: 44, iconSize: 20, background: DesignTokens.Colors.surface2)
        }
    }
}
