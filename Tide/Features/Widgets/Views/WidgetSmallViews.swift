import SwiftUI
import TideCore

/// A-7 1-A 小: リング104「72」、下に pin10＋「城ヶ島」。
struct WidgetScoreSmallView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        VStack(spacing: Wdg.smallNameTop) {
            ZStack {
                RingView(progress: Double(snapshot.total(at: now, timeZone: Tide736.timeZone)) / 100,
                         size: Wdg.smallRingSize, radius: Wdg.smallRingRadius, lineWidth: Wdg.smallRingLineWidth)
                Text("\(snapshot.total(at: now, timeZone: Tide736.timeZone))")
                    .font(DesignTokens.Fonts.text(Wdg.smallNumberFontSize, .w200))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }
            HStack(spacing: Wdg.smallNameGap) {
                IconView(icon: .pin, size: Wdg.smallPinSize, lineWidth: 2, color: DesignTokens.Colors.orange)
                Text(WidgetText.shortName(snapshot.spotName))
                    .font(DesignTokens.Fonts.text(Wdg.smallNameFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A-7 1-B 小: moon18＋「大潮 ↑」、24本バー、カメラピル。
struct WidgetHoursSmallView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MoonGlyph(age: snapshot.moonAge, size: Wdg.hoursMoonSize, radius: Wdg.hoursMoonSize * 0.425)
                Spacer(minLength: 0)
                Text("\(snapshot.tideTypeLabel) \(snapshot.isRising ? "↑" : "↓")")
                    .font(DesignTokens.Fonts.text(Wdg.hoursLabelFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer(minLength: 0)
            WidgetHourBars(values: snapshot.hourly, currentHour: WidgetText.hour(now))
                .frame(height: Wdg.hoursBarHeight)
            Spacer(minLength: 0)
            WidgetCameraPill(height: Wdg.hoursCameraHeight, radius: Wdg.hoursCameraRadius, iconSize: Wdg.hoursCameraIconSize)
        }
        .padding(.top, Wdg.hoursPadTop)
        .padding(.horizontal, Wdg.hoursPadHorizontal)
        .padding(.bottom, Wdg.hoursPadBottom)
    }
}

/// 24本バー（ウィジェット版: gap3 r2 高さ 6+値×0.55、他=非アクティブ色）。
struct WidgetHourBars: View {
    let values: [Int]
    let currentHour: Int?

    private typealias Wdg = DesignTokens.Widgets

    var body: some View {
        HStack(alignment: .bottom, spacing: Wdg.hoursBarGap) {
            ForEach(Array(values.prefix(24).enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: Wdg.hoursBarRadius, style: .continuous)
                    .fill(color(index: index, value: value))
                    .frame(height: Wdg.hoursBarBase + CGFloat(value) * Wdg.hoursBarScale)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func color(index: Int, value: Int) -> Color {
        if index == currentHour { return DesignTokens.Colors.orange }
        if value >= DesignTokens.HourBar.highlightThreshold { return DesignTokens.Colors.primary }
        return DesignTokens.Colors.inactive
    }
}

/// カメラピル（橙、黒のカメラ）。tide://catch へ。
struct WidgetCameraPill: View {
    var height: CGFloat
    var radius: CGFloat
    var iconSize: CGFloat

    var body: some View {
        Link(destination: DeepLink.catchScreen.url) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(DesignTokens.Colors.orange)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .overlay {
                    IconView(icon: .camera, size: iconSize, lineWidth: 2, color: DesignTokens.Colors.black)
                }
        }
    }
}

enum WidgetText {
    /// 「城ヶ島 西側」→「城ヶ島」
    static func shortName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    static func hour(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Tide736.timeZone
        return cal.component(.hour, from: date)
    }
}
