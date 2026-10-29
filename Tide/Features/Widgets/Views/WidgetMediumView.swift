import SwiftUI
import TideCore

/// A-7 2 中: 左リング120「72」、右に4条件＋ボタン行。
struct WidgetMediumView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        HStack(spacing: Wdg.mediumGap) {
            ZStack {
                RingView(progress: Double(snapshot.total(at: now, timeZone: Tide736.timeZone)) / 100,
                         size: Wdg.mediumRingSize, radius: Wdg.mediumRingRadius, lineWidth: Wdg.mediumRingLineWidth)
                Text("\(snapshot.total(at: now, timeZone: Tide736.timeZone))")
                    .font(DesignTokens.Fonts.text(Wdg.mediumNumberFontSize, .w200))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }
            VStack(spacing: Wdg.mediumRightGap) {
                HStack(spacing: 0) {
                    ForEach(Array(snapshot.meters.enumerated()), id: \.offset) { _, meter in
                        VStack(spacing: Wdg.mediumRightGap / 2) {
                            IconView(icon: WidgetIcons.icon(for: meter.key), size: Wdg.mediumIconSize, lineWidth: Wdg.mediumIconLineWidth)
                                .rotationEffect(meter.key == "wind" ? .degrees(meter.rotationDegrees) : .zero)
                            MeterView(fraction: meter.fraction, color: DesignTokens.Colors.named(meter.color),
                                      width: Wdg.mediumMeterWidth, height: Wdg.mediumMeterHeight,
                                      trackColor: DesignTokens.Colors.inactive)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: Wdg.mediumButtonGap) {
                    WidgetCameraPill(height: Wdg.mediumCameraHeight, radius: Wdg.mediumCameraRadius,
                                     iconSize: Wdg.mediumCameraIconSize)
                    Link(destination: DeepLink.home.url) {
                        Circle()
                            .fill(DesignTokens.Colors.surface2)
                            .frame(width: Wdg.mediumRoundSize, height: Wdg.mediumRoundSize)
                            .overlay {
                                IconView(icon: .dots, size: Wdg.mediumRoundIconSize, lineWidth: 2)
                            }
                    }
                }
            }
        }
        .padding(.vertical, Wdg.mediumPadVertical)
        .padding(.horizontal, Wdg.mediumPadHorizontal)
    }
}

enum WidgetIcons {
    static func icon(for key: String) -> TideIcon {
        switch key {
        case "wind": .wind
        case "wave": .wave
        case "drop": .drop
        case "pressure": .pressure
        default: .dots
        }
    }
}
