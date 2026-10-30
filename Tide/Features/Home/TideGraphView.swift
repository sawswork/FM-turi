import SwiftUI
import TideCore

/// A-1 5 潮位グラフ: 横スクロール、1日 350×150 × 3日。
struct TideGraphView: View {
    let days: [TideDay]
    @Binding var selected: Int
    var timeZone: TimeZone = Tide736.timeZone

    @State private var scrolledDay: Int? = 0

    private var range: (min: Double, max: Double) {
        let all = days.flatMap(\.levels)
        guard let lo = all.min(), let hi = all.max(), hi > lo else { return (0, 1) }
        return (lo, hi)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        TideDayGraph(day: day,
                                     isHighlighted: index == selected,
                                     isToday: index == 0,
                                     isLast: index == days.count - 1,
                                     now: context.date,
                                     range: range,
                                     timeZone: timeZone)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.leading)
            .scrollPosition(id: $scrolledDay)
            .contentMargins(.horizontal, DesignTokens.Screen.horizontalPadding, for: .scrollContent)
        }
        .frame(height: DesignTokens.TideGraph.height)
        .padding(.top, DesignTokens.TideGraph.marginTop)
        .onChange(of: selected) { _, newValue in
            withAnimation { scrolledDay = newValue }
        }
        .onChange(of: scrolledDay) { _, newValue in
            if let newValue, newValue != selected { selected = newValue }
        }
    }
}

/// 1日分の描画。
struct TideDayGraph: View {
    let day: TideDay
    let isHighlighted: Bool
    let isToday: Bool
    let isLast: Bool
    let now: Date
    let range: (min: Double, max: Double)
    let timeZone: TimeZone

    private typealias Graph = DesignTokens.TideGraph

    @MainActor private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = Tide736.timeZone
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        Canvas { context, _ in
            drawBands(in: &context)
            drawSunArc(in: &context)
            drawCurve(in: &context)
            drawTicks(in: &context)
            if !isLast { drawBoundary(in: &context) }
            if isToday { drawNow(in: &context) }
        }
        .frame(width: Graph.dayWidth, height: Graph.height)
    }

    // MARK: - 座標

    private func x(for date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(day.dayStart) / 86_400) * Graph.dayWidth
    }

    private func y(for level: Double) -> CGFloat {
        let span = range.max - range.min
        guard span > 0 else { return (Graph.curveTop + Graph.curveBottom) / 2 }
        let fraction = (level - range.min) / span
        return Graph.curveBottom - CGFloat(fraction) * (Graph.curveBottom - Graph.curveTop)
    }

    // MARK: - 描画

    private func drawBands(in context: inout GraphicsContext) {
        let centers: [CGFloat]
        if let sunrise = day.sunrise, let sunset = day.sunset {
            centers = [x(for: sunrise), x(for: sunset)]
        } else {
            centers = Graph.bandDefaultX.map { $0 + Graph.bandWidth / 2 }
        }
        let opacity = isHighlighted ? Graph.bandOpacityToday : Graph.bandOpacityOther
        for center in centers {
            let rect = CGRect(x: center - Graph.bandWidth / 2, y: Graph.bandY, width: Graph.bandWidth, height: Graph.bandHeight)
            context.fill(Path(roundedRect: rect, cornerRadius: Graph.bandRadius),
                         with: .color(DesignTokens.Colors.primary.opacity(opacity)))
        }
    }

    private func drawSunArc(in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: Graph.sunArcStart)
        path.addQuadCurve(to: Graph.sunArcEnd, control: Graph.sunArcControl)
        context.stroke(path, with: .color(DesignTokens.Colors.primary.opacity(Graph.sunArcOpacity)),
                       style: StrokeStyle(lineWidth: Graph.sunArcLineWidth, lineCap: .round, dash: Graph.sunArcDash))
    }

    private func curvePath() -> Path {
        var path = Path()
        for (index, level) in day.levels.enumerated() {
            let point = CGPoint(x: CGFloat(Double(index) * day.interval / 86_400) * Graph.dayWidth, y: y(for: level))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    private func drawCurve(in context: inout GraphicsContext) {
        guard day.levels.count >= 2 else { return }
        let curve = curvePath()
        var fill = curve
        let lastX = CGFloat(Double(day.levels.count - 1) * day.interval / 86_400) * Graph.dayWidth
        fill.addLine(to: CGPoint(x: lastX, y: Graph.fillBottom))
        fill.addLine(to: CGPoint(x: 0, y: Graph.fillBottom))
        fill.closeSubpath()
        context.fill(fill, with: .color(DesignTokens.Colors.primary.opacity(Graph.fillOpacity)))
        let opacity = isHighlighted ? 1 : Graph.curveOpacityOther
        context.stroke(curve, with: .color(DesignTokens.Colors.primary.opacity(opacity)),
                       style: StrokeStyle(lineWidth: Graph.curveLineWidth, lineCap: .round, lineJoin: .round))
    }

    private func drawTicks(in context: inout GraphicsContext) {
        for (label, tickX) in zip(Graph.tickLabels, Graph.tickX) {
            let text = Text(label)
                .font(DesignTokens.Fonts.text(Graph.tickFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.secondary)
            context.draw(text, at: CGPoint(x: tickX, y: Graph.tickY), anchor: .leading)
        }
    }

    private func drawBoundary(in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: CGPoint(x: Graph.dayWidth, y: Graph.boundaryTop))
        path.addLine(to: CGPoint(x: Graph.dayWidth, y: Graph.boundaryBottom))
        context.stroke(path, with: .color(DesignTokens.Colors.primary.opacity(Graph.boundaryOpacity)), lineWidth: 1)
    }

    private func drawNow(in context: inout GraphicsContext) {
        guard now >= day.dayStart, now < day.dayStart.addingTimeInterval(86_400) else { return }
        // 太陽の点（日中のみ、弧の上）
        if let sunrise = day.sunrise, let sunset = day.sunset, now >= sunrise, now <= sunset {
            let u = CGFloat(now.timeIntervalSince(sunrise) / sunset.timeIntervalSince(sunrise))
            let p0 = Graph.sunArcStart, c = Graph.sunArcControl, p1 = Graph.sunArcEnd
            let sun = CGPoint(x: (1 - u) * (1 - u) * p0.x + 2 * (1 - u) * u * c.x + u * u * p1.x,
                              y: (1 - u) * (1 - u) * p0.y + 2 * (1 - u) * u * c.y + u * u * p1.y)
            context.fill(Path(ellipseIn: CGRect(x: sun.x - Graph.sunHaloRadius, y: sun.y - Graph.sunHaloRadius,
                                                width: Graph.sunHaloRadius * 2, height: Graph.sunHaloRadius * 2)),
                         with: .color(DesignTokens.Colors.primary.opacity(Graph.sunHaloOpacity)))
            context.fill(Path(ellipseIn: CGRect(x: sun.x - Graph.sunPointRadius, y: sun.y - Graph.sunPointRadius,
                                                width: Graph.sunPointRadius * 2, height: Graph.sunPointRadius * 2)),
                         with: .color(DesignTokens.Colors.primary))
        }
        // 現在線
        let nowX = x(for: now)
        var line = Path()
        line.move(to: CGPoint(x: nowX, y: Graph.nowLineTop))
        line.addLine(to: CGPoint(x: nowX, y: Graph.nowLineBottom))
        context.stroke(line, with: .color(DesignTokens.Colors.orange.opacity(Graph.nowLineOpacity)),
                       style: StrokeStyle(lineWidth: 1, dash: Graph.nowLineDash))
        // 現在点
        if let level = day.level(at: now) {
            let center = CGPoint(x: nowX, y: y(for: level))
            context.fill(Path(ellipseIn: CGRect(x: center.x - Graph.nowHaloRadius, y: center.y - Graph.nowHaloRadius,
                                                width: Graph.nowHaloRadius * 2, height: Graph.nowHaloRadius * 2)),
                         with: .color(DesignTokens.Colors.orange.opacity(Graph.nowHaloOpacity)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - Graph.nowPointRadius, y: center.y - Graph.nowPointRadius,
                                                width: Graph.nowPointRadius * 2, height: Graph.nowPointRadius * 2)),
                         with: .color(DesignTokens.Colors.orange))
        }
        // 時刻
        let label = Text(Self.timeFormatter.string(from: now))
            .font(DesignTokens.Fonts.text(Graph.nowLabelFontSize, .w600))
            .foregroundStyle(DesignTokens.Colors.orange)
        context.draw(label, at: CGPoint(x: nowX + Graph.nowLabelOffset.x, y: Graph.nowLabelOffset.y), anchor: .leading)
    }
}

#Preview {
    @Previewable @State var selected = 0
    let jst = Tide736.timeZone
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = jst
    let start = cal.startOfDay(for: Date())
    let point = GeoPoint(latitude: 35.1352, longitude: 139.6079)
    let days = (0..<3).map {
        MockTideProvider.synthesize(dayStart: start.addingTimeInterval(Double($0) * 86_400), point: point,
                                    timeZone: jst, fetchedAt: Date())
    }
    return ZStack {
        DesignTokens.Colors.background.ignoresSafeArea()
        VStack(spacing: 0) {
            DateChipRow(days: days, selected: $selected)
            TideGraphView(days: days, selected: $selected)
        }
    }
}
