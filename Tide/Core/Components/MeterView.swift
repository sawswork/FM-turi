import SwiftUI

/// メーター: 既定 40×4 r2、トラック 面2、左から割合で塗る。
struct MeterView: View {
    /// 0...1
    let fraction: Double
    var color: Color = DesignTokens.Colors.primary
    var width: CGFloat = DesignTokens.Meter.width
    var height: CGFloat = DesignTokens.Meter.height
    var radius: CGFloat = DesignTokens.Meter.radius
    var trackColor: Color = DesignTokens.Colors.surface2

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(trackColor)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                .frame(width: width * min(max(fraction, 0), 1))
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 12) {
            MeterView(fraction: 0.60, color: DesignTokens.Colors.orange)
            MeterView(fraction: 0.22)
            MeterView(fraction: 0.80, color: DesignTokens.Colors.green)
            MeterView(fraction: 0.45, color: DesignTokens.Colors.green)
        }
    }
}
