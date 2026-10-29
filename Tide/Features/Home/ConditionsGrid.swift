import SwiftUI

/// A-1 3 4条件: 4列 gap10 pad=0 36、各h60 縦中央 gap12、アイコン24白＋メーター。
struct ConditionsGrid: View {
    let meters: [HomeScore.Meter]
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Conditions.gap) {
                ForEach(meters) { meter in
                    VStack(spacing: DesignTokens.Conditions.iconMeterGap) {
                        IconView(icon: meter.icon, size: DesignTokens.Conditions.iconSize)
                            .rotationEffect(meter.icon == .wind ? meter.rotation : .zero)
                        MeterView(fraction: meter.fraction, color: meter.color)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Conditions.cellHeight)
                }
            }
            .padding(.horizontal, DesignTokens.Conditions.padHorizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        ConditionsGrid(meters: [
            HomeScore.Meter(icon: .wind, fraction: 0.6, color: DesignTokens.Colors.orange, rotation: .degrees(40)),
            HomeScore.Meter(icon: .wave, fraction: 0.22, color: DesignTokens.Colors.primary, rotation: .zero),
            HomeScore.Meter(icon: .drop, fraction: 0.8, color: DesignTokens.Colors.green, rotation: .zero),
            HomeScore.Meter(icon: .pressure, fraction: 0.45, color: DesignTokens.Colors.green, rotation: .zero)
        ])
    }
}
