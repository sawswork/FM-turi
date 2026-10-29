import SwiftUI

/// A-1 2 リング領域: h268、リング240、中央「72」86/200 字間-4、その8下に 5×5 の点×5。
struct ScoreRingView: View {
    let total: Int
    var action: () -> Void = {}

    private typealias Ring = DesignTokens.HomeRing

    var body: some View {
        Button(action: action) {
            ZStack {
                RingView(progress: Double(total) / 100,
                         size: Ring.size, radius: Ring.radius, lineWidth: Ring.lineWidth,
                         haloLineWidth: Ring.haloLineWidth, haloOpacity: Ring.haloOpacity)
                Text("\(total)")
                    .font(DesignTokens.Fonts.text(Ring.numberFontSize, .w200))
                    .tracking(Ring.numberTracking)
                    .foregroundStyle(DesignTokens.Colors.primary)
                HStack(spacing: Ring.dotGap) {
                    ForEach(0..<Ring.dotCount, id: \.self) { index in
                        Circle()
                            .fill(index < total / 20 ? DesignTokens.Colors.orange : DesignTokens.Colors.inactive)
                            .frame(width: Ring.dotSize, height: Ring.dotSize)
                    }
                }
                .offset(y: Ring.dotsOffsetY)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Ring.areaHeight)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        ScoreRingView(total: 72)
    }
}
