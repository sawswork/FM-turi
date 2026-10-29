import SwiftUI
import TideCore

/// A-7 3 大: 見出し、潮位曲線 318×78、シンカー行（−/+）、フック行（−/+）、下段ボタン。
struct WidgetLargeView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        VStack(spacing: Wdg.largeGap) {
            HStack(spacing: 0) {
                HStack(spacing: DesignTokens.LocationPill.gap) {
                    IconView(icon: .pin, size: Wdg.largePinSize, lineWidth: 2, color: DesignTokens.Colors.orange)
                    Text(snapshot.spotName)
                        .font(DesignTokens.Fonts.text(Wdg.largeTitleFontSize, .w600))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(TimeFormat.monthDayWeekday.string(from: now))
                    .font(DesignTokens.Fonts.text(Wdg.largeTitleFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            WidgetTideCurve(levels: snapshot.tideLevels, dayStart: snapshot.dayStart, now: now)
                .frame(height: Wdg.largeCurveSize.height)
            stockRow(items: snapshot.sinkers, kind: "sinker", icon: .sinker, columns: 5, gap: Wdg.largeSinkerGap,
                     height: Wdg.largeSinkerStepperHeight, radius: Wdg.largeSinkerStepperRadius,
                     buttonWidth: Wdg.largeSinkerStepperButtonWidth, signSize: Wdg.largeSinkerStepperSignFontSize,
                     valueSize: Wdg.largeSinkerStepperValueFontSize, lowThreshold: Wdg.largeSinkerLowThreshold)
            stockRow(items: snapshot.hooks, kind: "hook", icon: .hook, columns: 4, gap: Wdg.largeHookGap,
                     height: Wdg.largeHookStepperHeight, radius: Wdg.largeHookStepperRadius,
                     buttonWidth: Wdg.largeHookStepperButtonWidth, signSize: Wdg.largeHookStepperSignFontSize,
                     valueSize: Wdg.largeHookStepperValueFontSize, lowThreshold: Wdg.largeHookLowThreshold)
            Spacer(minLength: 0)
            HStack(spacing: Wdg.largeBottomGap) {
                WidgetCameraPill(height: Wdg.largeCameraHeight, radius: Wdg.largeCameraRadius, iconSize: Wdg.largeCameraIconSize)
                roundLink(icon: .book, url: DeepLink.zukan.url)
                roundLink(icon: .hook, url: DeepLink.tackle.url)
            }
        }
        .padding(.vertical, Wdg.largePadVertical)
        .padding(.horizontal, Wdg.largePadHorizontal)
    }

    private func roundLink(icon: TideIcon, url: URL) -> some View {
        Link(destination: url) {
            Circle()
                .fill(DesignTokens.Colors.surface2)
                .frame(width: Wdg.largeRoundSize, height: Wdg.largeRoundSize)
                .overlay { IconView(icon: icon, size: Wdg.largeRoundIconSize, lineWidth: 2) }
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func stockRow(items: [WidgetSnapshot.Stock], kind: String, icon: TideIcon, columns: Int, gap: CGFloat,
                          height: CGFloat, radius: CGFloat, buttonWidth: CGFloat, signSize: CGFloat,
                          valueSize: CGFloat, lowThreshold: Int) -> some View {
        HStack(spacing: gap) {
            ForEach(Array(items.prefix(columns).enumerated()), id: \.offset) { _, item in
                VStack(spacing: Wdg.largeGap / 2) {
                    HStack(spacing: DesignTokens.Chip.gap / 2) {
                        IconView(icon: icon, size: Wdg.largeSinkerIconSize, lineWidth: 1.5, color: DesignTokens.Colors.secondary)
                        Text(item.label)
                            .font(DesignTokens.Fonts.text(Wdg.largeStockLabelFontSize, .w600))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    HStack(spacing: 0) {
                        Button(intent: AdjustStockIntent(kind: kind, label: item.label, delta: -1)) {
                            Text("−")
                                .font(DesignTokens.Fonts.text(signSize, .w500))
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .frame(width: buttonWidth, height: height)
                        }
                        .buttonStyle(.plain)
                        Text("\(item.count)")
                            .font(DesignTokens.Fonts.text(valueSize, .w600))
                            .foregroundStyle(item.count <= lowThreshold ? DesignTokens.Colors.orange : DesignTokens.Colors.primary)
                            .frame(maxWidth: .infinity)
                        Button(intent: AdjustStockIntent(kind: kind, label: item.label, delta: 1)) {
                            Text("+")
                                .font(DesignTokens.Fonts.text(signSize, .w500))
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .frame(width: buttonWidth, height: height)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: height)
                    .background(DesignTokens.Colors.surface2, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// 大ウィジェットの潮位曲線（毎正時24点、現在点は橙、目盛 0 6 12 18）。
struct WidgetTideCurve: View {
    let levels: [Double]
    let dayStart: Date
    let now: Date

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        Canvas { context, size in
            guard levels.count >= 2, let lo = levels.min(), let hi = levels.max() else { return }
            let span = max(hi - lo, 1)
            func y(_ level: Double) -> CGFloat {
                Wdg.largeCurveBottom - CGFloat((level - lo) / span) * (Wdg.largeCurveBottom - Wdg.largeCurveTop)
            }
            func x(_ hour: Double) -> CGFloat { CGFloat(hour / 24) * size.width }
            var path = Path()
            for (index, level) in levels.enumerated() {
                let point = CGPoint(x: x(Double(index)), y: y(level))
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            var fill = path
            fill.addLine(to: CGPoint(x: x(Double(levels.count - 1)), y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .color(DesignTokens.Colors.primary.opacity(Wdg.largeCurveFillOpacity)))
            context.stroke(path, with: .color(DesignTokens.Colors.primary),
                           style: StrokeStyle(lineWidth: Wdg.largeCurveLineWidth, lineCap: .round, lineJoin: .round))
            for (label, tickX) in zip(DesignTokens.TideGraph.tickLabels, Wdg.largeTickX) {
                let text = Text(label)
                    .font(DesignTokens.Fonts.text(Wdg.largeTickFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                context.draw(text, at: CGPoint(x: tickX, y: Wdg.largeTickY), anchor: .leading)
            }
            let hours = now.timeIntervalSince(dayStart) / 3600
            guard hours >= 0, hours <= 24 else { return }
            let index = Int(hours)
            let next = min(index + 1, levels.count - 1)
            let fraction = hours - Double(index)
            let level = levels[min(index, levels.count - 1)] * (1 - fraction) + levels[next] * fraction
            let center = CGPoint(x: x(hours), y: y(level))
            context.fill(Path(ellipseIn: CGRect(x: center.x - Wdg.largeNowHaloRadius, y: center.y - Wdg.largeNowHaloRadius,
                                                width: Wdg.largeNowHaloRadius * 2, height: Wdg.largeNowHaloRadius * 2)),
                         with: .color(DesignTokens.Colors.orange.opacity(Wdg.largeNowHaloOpacity)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - Wdg.largeNowRadius, y: center.y - Wdg.largeNowRadius,
                                                width: Wdg.largeNowRadius * 2, height: Wdg.largeNowRadius * 2)),
                         with: .color(DesignTokens.Colors.orange))
            let label = Text(TimeFormat.hourMinute.string(from: now))
                .font(DesignTokens.Fonts.text(Wdg.largeNowLabelFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.orange)
            context.draw(label, at: CGPoint(x: center.x + Wdg.largeNowLabelOffset.x, y: center.y + Wdg.largeNowLabelOffset.y),
                         anchor: .leading)
        }
    }
}
