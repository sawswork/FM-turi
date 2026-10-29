import SwiftUI

/// 釣り針。上端のアイ→シャンク→ベンド→バーブ。
struct HookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + width * x, y: rect.minY + height * y)
        }
        // アイ（小さな輪）
        path.addEllipse(in: CGRect(x: rect.minX + width * 0.56, y: rect.minY + height * 0.04,
                                   width: width * 0.14, height: height * 0.14))
        // シャンク
        path.move(to: point(0.63, 0.18))
        path.addLine(to: point(0.63, 0.62))
        // ベンド（右→下→左）
        path.addArc(center: point(0.42, 0.62), radius: width * 0.21,
                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        // ポイントとバーブ
        path.addLine(to: point(0.21, 0.44))
        path.move(to: point(0.21, 0.44))
        path.addLine(to: point(0.33, 0.50))
        return path
    }
}

/// シンカー（逆五角形の重り）。上に小さなアイ。
struct SinkerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + width * x, y: rect.minY + height * y)
        }
        path.addEllipse(in: CGRect(x: rect.minX + width * 0.42, y: rect.minY + height * 0.04,
                                   width: width * 0.16, height: height * 0.16))
        path.move(to: point(0.22, 0.26))
        path.addLine(to: point(0.78, 0.26))
        path.addLine(to: point(0.86, 0.62))
        path.addLine(to: point(0.50, 0.96))
        path.addLine(to: point(0.14, 0.62))
        path.closeSubpath()
        return path
    }
}

/// 魚（左向きシルエット）。
struct FishShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + width * x, y: rect.minY + height * y)
        }
        // 体（頭が左）
        path.move(to: point(0.04, 0.50))
        path.addCurve(to: point(0.72, 0.50), control1: point(0.22, 0.10), control2: point(0.56, 0.10))
        path.addCurve(to: point(0.04, 0.50), control1: point(0.56, 0.90), control2: point(0.22, 0.90))
        // 尾
        path.move(to: point(0.72, 0.50))
        path.addLine(to: point(0.96, 0.22))
        path.addLine(to: point(0.96, 0.78))
        path.closeSubpath()
        // 目
        path.addEllipse(in: CGRect(x: rect.minX + width * 0.20, y: rect.minY + height * 0.40,
                                   width: width * 0.06, height: height * 0.06))
        return path
    }
}

/// 二重の波線。
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for row in [0.36, 0.64] {
            let y = rect.minY + rect.height * row
            let amp = rect.height * 0.12
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: y))
            path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.50, y: y),
                          control1: CGPoint(x: rect.minX + rect.width * 0.22, y: y - amp * 2),
                          control2: CGPoint(x: rect.minX + rect.width * 0.36, y: y + amp * 2))
            path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.92, y: y),
                          control1: CGPoint(x: rect.minX + rect.width * 0.64, y: y - amp * 2),
                          control2: CGPoint(x: rect.minX + rect.width * 0.78, y: y + amp * 2))
        }
        return path
    }
}

/// 半円ゲージ＋針＋下矢印（気圧）。
struct PressureShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.58)
        let radius = rect.width * 0.40
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        // 針（中心から左上へ）
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x - radius * 0.62, y: center.y - radius * 0.62))
        // 下矢印
        let arrowX = rect.midX
        path.move(to: CGPoint(x: arrowX, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: arrowX, y: rect.minY + rect.height * 0.94))
        path.move(to: CGPoint(x: arrowX - rect.width * 0.10, y: rect.minY + rect.height * 0.84))
        path.addLine(to: CGPoint(x: arrowX, y: rect.minY + rect.height * 0.94))
        path.addLine(to: CGPoint(x: arrowX + rect.width * 0.10, y: rect.minY + rect.height * 0.84))
        return path
    }
}
