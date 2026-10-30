import SwiftUI

/// A-2 1 写真枠のガイド: 魚の輪郭、四隅のL字枠、横点線。
struct CatchPhotoFrame: View {
    /// ステータスバー分。仕様の y 座標はこの下の領域に縮めて配置する（閉じる・チップと重ならないように）
    var topInset: CGFloat = 0

    private typealias Cat = DesignTokens.Catch

    var body: some View {
        Canvas { context, size in
            let scaleY = max(size.height - topInset, 1) / max(size.height, 1)
            func sy(_ y: CGFloat) -> CGFloat { topInset + y * scaleY }
            // 魚の輪郭（中央）
            let guideRect = CGRect(x: (size.width - Cat.guideSize.width) / 2,
                                   y: topInset + (size.height - topInset - Cat.guideSize.height) / 2,
                                   width: Cat.guideSize.width, height: Cat.guideSize.height)
            let fish = FishSilhouette(kind: .rock).path(in: guideRect)
            context.fill(fish, with: .color(DesignTokens.Colors.primary.opacity(Cat.guideFillOpacity)))
            context.stroke(fish, with: .color(DesignTokens.Colors.primary.opacity(Cat.guideOpacity)),
                           style: StrokeStyle(lineWidth: Cat.guideLineWidth, lineJoin: .round))
            // 四隅のL字枠
            let brackets: [(CGPoint, CGFloat, CGFloat)] = [
                (Cat.bracketTopLeft, 1, 1), (Cat.bracketTopRight, -1, 1),
                (Cat.bracketBottomLeft, 1, -1), (Cat.bracketBottomRight, -1, -1)
            ]
            for (spec, sx, dy) in brackets {
                let corner = CGPoint(x: spec.x, y: sy(spec.y))
                var path = Path()
                path.move(to: CGPoint(x: corner.x, y: corner.y + dy * Cat.bracketLength))
                path.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * Cat.bracketRadius))
                path.addQuadCurve(to: CGPoint(x: corner.x + sx * Cat.bracketRadius, y: corner.y), control: corner)
                path.addLine(to: CGPoint(x: corner.x + sx * Cat.bracketLength, y: corner.y))
                context.stroke(path, with: .color(DesignTokens.Colors.primary),
                               style: StrokeStyle(lineWidth: Cat.bracketLineWidth, lineCap: .round))
            }
            // 横点線
            var dotted = Path()
            dotted.move(to: CGPoint(x: Cat.dottedX0, y: sy(Cat.dottedY)))
            dotted.addLine(to: CGPoint(x: Cat.dottedX1, y: sy(Cat.dottedY)))
            context.stroke(dotted, with: .color(DesignTokens.Colors.primary.opacity(Cat.dottedOpacity)),
                           style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: Cat.dottedDash))
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CatchPhotoFrame()
        .frame(width: 390, height: 480)
        .background(DesignTokens.Colors.surface3)
}
