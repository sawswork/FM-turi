import SwiftUI

/// 月相グリフ: 既定 20×20。白円 r8.5 の上に黒(不透明度0.78)の影。
/// 月齢 0=新月（全面影）、14.77=満月、12.4=右がほぼ満ちて左に細い影。
struct MoonGlyph: View {
    /// 月齢（0 ..< 29.53）
    let age: Double
    var size: CGFloat = DesignTokens.MoonGlyph.size
    var radius: CGFloat = DesignTokens.MoonGlyph.radius

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.Colors.primary)
                .frame(width: radius * 2, height: radius * 2)
            MoonShadowShape(age: age)
                .fill(DesignTokens.Colors.black.opacity(DesignTokens.MoonGlyph.shadowOpacity))
                .frame(width: radius * 2, height: radius * 2)
        }
        .frame(width: size, height: size)
    }
}

/// 月の影の形。朔望月 29.53 日。前半（上弦側）は右から満ち、後半は右から欠ける。
struct MoonShadowShape: Shape {
    static let synodicMonth = 29.530_588_853

    var age: Double

    var animatableData: Double {
        get { age }
        set { age = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let phase = (age / Self.synodicMonth).truncatingRemainder(dividingBy: 1)
        let normalized = phase < 0 ? phase + 1 : phase
        // k: 明暗境界の膨らみ。+1=新月（全面影）、-1=満月（影なし）
        let k = cos(2 * .pi * normalized)
        let waxing = normalized < 0.5
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // 影は「暗い側の半円 ∪/− 楕円」。暗い側は 上弦側（waxing）なら左、下弦側なら右。
        let side: CGFloat = waxing ? -1 : 1
        let kappa: CGFloat = 4.0 / 3.0
        let top = CGPoint(x: center.x, y: center.y - r)
        let bottom = CGPoint(x: center.x, y: center.y + r)
        var path = Path()
        path.move(to: top)
        // 暗い側の半円（top → bottom）
        path.addCurve(to: bottom,
                      control1: CGPoint(x: center.x + side * kappa * r, y: top.y),
                      control2: CGPoint(x: center.x + side * kappa * r, y: bottom.y))
        // 明暗境界の半楕円（bottom → top）。x 方向の半径 = r*k を暗い側と逆向きに取る
        let bulge = -side * CGFloat(k) * r
        path.addCurve(to: top,
                      control1: CGPoint(x: center.x + kappa * bulge, y: bottom.y),
                      control2: CGPoint(x: center.x + kappa * bulge, y: top.y))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ForEach([0.0, 3.7, 7.4, 12.0, 12.4, 13.0, 14.8, 16.0], id: \.self) { age in
                    MoonGlyph(age: age)
                }
            }
            HStack(spacing: 14) {
                ForEach([18.0, 22.1, 25.0, 27.0, 29.0], id: \.self) { age in
                    MoonGlyph(age: age, size: 40, radius: 17)
                }
            }
        }
    }
}
