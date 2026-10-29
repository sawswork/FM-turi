import SwiftUI

/// リング: 12時から時計回りに progress を塗る。
/// Home: size240 r102 線幅13 ハロー線幅28 橙0.10 / Detail: 120 r50 9 / 図鑑: 36 r15 4 白 など。
struct RingView: View {
    /// 0...1
    let progress: Double
    var size: CGFloat
    var radius: CGFloat
    var lineWidth: CGFloat
    var color: Color = DesignTokens.Colors.orange
    var trackColor: Color = DesignTokens.Colors.surface2
    var haloLineWidth: CGFloat?
    var haloOpacity: Double = 0.10

    var body: some View {
        ZStack {
            if let haloLineWidth {
                Circle()
                    .stroke(color.opacity(haloOpacity), lineWidth: haloLineWidth)
                    .frame(width: radius * 2, height: radius * 2)
            }
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 24) {
            RingView(progress: 0.72, size: 240, radius: 102, lineWidth: 13, haloLineWidth: 28)
            HStack(spacing: 24) {
                RingView(progress: 0.72, size: 120, radius: 50, lineWidth: 9)
                RingView(progress: 0.58, size: 36, radius: 15, lineWidth: 4, color: DesignTokens.Colors.primary)
                RingView(progress: 0.61, size: 52, radius: 20, lineWidth: 4, color: DesignTokens.Colors.primary)
            }
        }
    }
}
