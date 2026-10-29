import SwiftUI
import TideCore

/// A-2 3 潮位ミニ曲線 26×16、現在点は橙。
struct MiniTideCurve: View {
    let day: TideDay?
    let now: Date

    var body: some View {
        Canvas { context, size in
            guard let day, day.levels.count >= 2, let lo = day.levels.min(), let hi = day.levels.max() else { return }
            let span = max(hi - lo, 1)
            func point(_ index: Int) -> CGPoint {
                let x = CGFloat(Double(index) * day.interval / 86_400) * size.width
                let y = size.height - CGFloat((day.levels[index] - lo) / span) * (size.height - 4) - 2
                return CGPoint(x: x, y: y)
            }
            var path = Path()
            for index in day.levels.indices {
                if index == 0 { path.move(to: point(index)) } else { path.addLine(to: point(index)) }
            }
            context.stroke(path, with: .color(DesignTokens.Colors.secondary), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            if let level = day.level(at: now) {
                let x = CGFloat(now.timeIntervalSince(day.dayStart) / 86_400) * size.width
                let y = size.height - CGFloat((level - lo) / span) * (size.height - 4) - 2
                context.fill(Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)),
                             with: .color(DesignTokens.Colors.orange))
            }
        }
        .frame(width: DesignTokens.Catch.miniCurveSize.width, height: DesignTokens.Catch.miniCurveSize.height)
    }
}
