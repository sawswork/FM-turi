import SwiftUI

/// A-1 6 24時間バー: h50 下揃え gap5、24本 r3、高さ=6+値×0.42。現在時=橙、≥60=白、他 面2。
struct HourBarView: View {
    /// 24個、0...100
    let values: [Int]
    /// 現在の時（今日のみ）。nil なら橙なし
    let currentHour: Int?

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.HourBar.gap) {
            ForEach(Array(values.prefix(24).enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: DesignTokens.HourBar.radius, style: .continuous)
                    .fill(color(index: index, value: value))
                    .frame(height: DesignTokens.HourBar.baseHeight + CGFloat(value) * DesignTokens.HourBar.scale)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: DesignTokens.HourBar.height, alignment: .bottom)
        .padding(.top, DesignTokens.HourBar.padTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
    }

    private func color(index: Int, value: Int) -> Color {
        if index == currentHour { return DesignTokens.Colors.orange }
        if value >= DesignTokens.HourBar.highlightThreshold { return DesignTokens.Colors.primary }
        return DesignTokens.Colors.surface2
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        HourBarView(values: [30, 22, 18, 16, 20, 34, 58, 74, 66, 48, 38, 30, 26, 24, 30, 44, 62, 80, 72, 52, 38, 30, 26, 22],
                    currentHour: 10)
    }
}
