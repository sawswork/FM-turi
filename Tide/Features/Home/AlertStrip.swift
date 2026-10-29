import SwiftUI

/// 気象警報・注意報（指示書 §3-1）。Home の上部帯の下に橙のピルで出す。無ければ何も出さない。
struct AlertStrip: View {
    let alerts: [String]

    var body: some View {
        if !alerts.isEmpty {
            VStack(spacing: DesignTokens.Chip.gap) {
                ForEach(Array(alerts.enumerated()), id: \.offset) { _, alert in
                    Text(alert)
                        .font(DesignTokens.Fonts.text(DesignTokens.Chip.fontSize, .w600))
                        .foregroundStyle(DesignTokens.Colors.black)
                        .lineLimit(1)
                        .padding(.horizontal, DesignTokens.Chip.padHorizontal)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Chip.height)
                        .background(DesignTokens.Colors.orange,
                                    in: RoundedRectangle(cornerRadius: DesignTokens.Chip.radius, style: .continuous))
                }
            }
            .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        }
    }
}
