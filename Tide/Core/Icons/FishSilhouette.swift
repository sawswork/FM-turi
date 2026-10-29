import SwiftUI
import TideCore

/// 魚のシルエット（左向き）。形4種 rock / long / flat / deep。
struct FishSilhouette: Shape {
    var kind: FishShapeKind

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + w * x, y: rect.minY + h * y) }
        switch kind {
        case .rock:
            // 頭が大きく背びれがギザギザ
            path.move(to: p(0.02, 0.55))
            path.addCurve(to: p(0.30, 0.18), control1: p(0.06, 0.30), control2: p(0.18, 0.18))
            path.addLine(to: p(0.36, 0.08))
            path.addLine(to: p(0.42, 0.20))
            path.addLine(to: p(0.48, 0.06))
            path.addLine(to: p(0.54, 0.20))
            path.addLine(to: p(0.60, 0.08))
            path.addLine(to: p(0.66, 0.22))
            path.addCurve(to: p(0.80, 0.42), control1: p(0.72, 0.24), control2: p(0.78, 0.32))
            path.addLine(to: p(0.98, 0.20))
            path.addLine(to: p(0.98, 0.80))
            path.addLine(to: p(0.80, 0.58))
            path.addCurve(to: p(0.02, 0.55), control1: p(0.70, 0.88), control2: p(0.20, 0.92))
            path.closeSubpath()
        case .long:
            // 細長い
            path.move(to: p(0.02, 0.50))
            path.addCurve(to: p(0.82, 0.38), control1: p(0.12, 0.22), control2: p(0.50, 0.22))
            path.addLine(to: p(0.98, 0.22))
            path.addLine(to: p(0.98, 0.78))
            path.addLine(to: p(0.82, 0.62))
            path.addCurve(to: p(0.02, 0.50), control1: p(0.50, 0.78), control2: p(0.12, 0.78))
            path.closeSubpath()
        case .flat:
            // 平たい楕円に小さな尾
            path.move(to: p(0.02, 0.50))
            path.addCurve(to: p(0.78, 0.46), control1: p(0.10, 0.06), control2: p(0.60, 0.04))
            path.addLine(to: p(0.98, 0.34))
            path.addLine(to: p(0.98, 0.66))
            path.addLine(to: p(0.78, 0.54))
            path.addCurve(to: p(0.02, 0.50), control1: p(0.60, 0.96), control2: p(0.10, 0.94))
            path.closeSubpath()
        case .deep:
            // 体高がある
            path.move(to: p(0.02, 0.52))
            path.addCurve(to: p(0.74, 0.40), control1: p(0.08, 0.14), control2: p(0.42, 0.02))
            path.addLine(to: p(0.98, 0.16))
            path.addLine(to: p(0.98, 0.84))
            path.addLine(to: p(0.74, 0.60))
            path.addCurve(to: p(0.02, 0.52), control1: p(0.42, 0.98), control2: p(0.08, 0.90))
            path.closeSubpath()
        }
        return path
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            ForEach(FishShapeKind.allCases, id: \.self) { kind in
                HStack(spacing: 16) {
                    FishSilhouette(kind: kind)
                        .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                        .frame(width: 56, height: 30)
                    FishSilhouette(kind: kind)
                        .fill(DesignTokens.Colors.primary)
                        .frame(width: 70, height: 36)
                }
            }
        }
    }
}
