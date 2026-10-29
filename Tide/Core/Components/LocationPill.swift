import SwiftUI

/// 位置ピル: h36 r18 bg 面 pad=0 14 0 10 gap7。pin15 橙 線幅2 ＋ 釣り場名 13/500 白。
struct LocationPill: View {
    let name: String
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: DesignTokens.LocationPill.gap) {
                IconView(icon: .pin,
                         size: DesignTokens.LocationPill.pinSize,
                         lineWidth: DesignTokens.LocationPill.pinLineWidth,
                         color: DesignTokens.Colors.orange)
                Text(name)
                    .font(DesignTokens.Fonts.text(DesignTokens.LocationPill.fontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .lineLimit(1)
            }
            .padding(.leading, DesignTokens.LocationPill.padLeading)
            .padding(.trailing, DesignTokens.LocationPill.padTrailing)
            .frame(height: DesignTokens.LocationPill.height)
            .background(
                DesignTokens.Colors.surface,
                in: RoundedRectangle(cornerRadius: DesignTokens.LocationPill.radius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        LocationPill(name: "城ヶ島 西側")
    }
}
