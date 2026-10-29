import SwiftUI
import TideCore

/// 付録A A-3 Detail。下からのシート（fullScreenCover）。
struct DetailView: View {
    let data: DetailData
    var onClose: () -> Void = {}

    private typealias Det = DesignTokens.Detail

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                RingView(progress: Double(data.score.total) / 100,
                         size: Det.ringSize, radius: Det.ringRadius, lineWidth: Det.ringLineWidth)
                    .opacity(Det.topOpacity)
                    .frame(height: Det.topHeight)
                Spacer(minLength: 0)
                sheet
                    .frame(maxHeight: Det.sheetHeight)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: Det.handleRadius, style: .continuous)
                .fill(DesignTokens.Colors.inactive)
                .frame(width: Det.handleWidth, height: Det.handleHeight)
                .padding(.bottom, Det.handleBottom)
            placeRow
                .padding(.bottom, Det.placeRowBottom)
            valueGrid
            moonRow
            breakdown
            Spacer(minLength: 0)
            Button(action: onClose) {
                IconView(icon: .chevronDown, size: Det.closeIconSize, color: DesignTokens.Colors.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Det.closeHeight)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Det.sheetPadTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        .frame(maxWidth: .infinity)
        .background(
            DesignTokens.Colors.sheet,
            in: UnevenRoundedRectangle(topLeadingRadius: Det.sheetRadius, topTrailingRadius: Det.sheetRadius, style: .continuous)
        )
    }

    // MARK: - 場所行

    private var placeRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: DesignTokens.LocationPill.gap) {
                IconView(icon: .pin, size: Det.placePinSize, lineWidth: 2, color: DesignTokens.Colors.orange)
                Text(data.spotName)
                    .font(DesignTokens.Fonts.text(Det.placeFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }
            Spacer(minLength: 0)
            Text(TimeFormat.monthDayWeekdayTime.string(from: data.date))
                .font(DesignTokens.Fonts.text(Det.placeFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
    }

    // MARK: - 数値グリッド

    private struct Cell: Identifiable {
        let label: String
        let value: String
        var unit: String = ""
        var trend: String = ""
        var trendColor: Color = DesignTokens.Colors.secondary
        var id: String { label }
    }

    private var cells: [Cell] {
        let tideLevel = data.tideLevelCm.map { String(format: "%.2f", $0 / 100) } ?? "—"
        let tideTrend = (data.isRising.map { $0 ? "↑" : "↓" } ?? "") + (data.tideType?.label ?? "")
        let wind = data.weather.map { String(format: "%.1f", $0.windSpeed) } ?? "—"
        let wave = data.marine.map { String(format: "%.1f", $0.waveHeight) } ?? "—"
        let period = data.marine.map { String(format: "%.0fs", $0.wavePeriod) } ?? ""
        let pressure = data.weather.map { String(format: "%.0f", $0.pressure) } ?? "—"
        let trend = data.weather?.pressureTrend3h ?? 0
        let pressureTrend = data.weather.map { _ in
            (trend < -0.5 ? "↓" : (trend > 0.5 ? "↑" : "→")) + String(format: "%.0f", abs(trend))
        } ?? ""
        return [
            Cell(label: "TIDE", value: tideLevel, unit: "m", trend: tideTrend,
                 trendColor: data.isRising == true ? DesignTokens.Colors.green : DesignTokens.Colors.secondary),
            Cell(label: "WIND", value: wind, unit: "m/s", trend: data.weather?.compassLabel ?? "",
                 trendColor: DesignTokens.Colors.orange),
            Cell(label: "WAVE", value: wave, unit: "m", trend: period),
            Cell(label: "PRESS", value: pressure, unit: "hPa", trend: pressureTrend,
                 trendColor: trend < -0.5 ? DesignTokens.Colors.green : DesignTokens.Colors.secondary),
            Cell(label: "SST", value: data.marine.map { String(format: "%.1f", $0.seaSurfaceTemperature) } ?? "—", unit: "°C"),
            Cell(label: "AIR", value: data.weather.map { String(format: "%.1f", $0.airTemperature) } ?? "—", unit: "°C"),
            Cell(label: "SUNRISE", value: TimeFormat.hm(data.sunrise)),
            Cell(label: "SUNSET", value: TimeFormat.hm(data.sunset)),
            Cell(label: "HIGH", value: TimeFormat.hm(data.highs.first), trend: data.highs.dropFirst().first.map(TimeFormat.hm) ?? ""),
            Cell(label: "LOW", value: TimeFormat.hm(data.lows.first), trend: data.lows.dropFirst().first.map(TimeFormat.hm) ?? "")
        ]
    }

    private var valueGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Det.gridColumnGap), GridItem(.flexible())], spacing: 0) {
            ForEach(cells) { cell in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(cell.label)
                            .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                            .tracking(Det.labelTracking)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        Spacer(minLength: 0)
                        Text(cell.trend)
                            .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                            .foregroundStyle(cell.trendColor)
                    }
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: Det.unitGap) {
                        Text(cell.value)
                            .font(DesignTokens.Fonts.text(Det.valueFontSize, .w300))
                            .tracking(Det.valueTracking)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Text(cell.unit)
                            .font(DesignTokens.Fonts.text(Det.unitFontSize, .w500))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .padding(.top, Det.cellPadTop)
                .padding(.bottom, Det.cellPadBottom)
                .frame(height: Det.cellHeight)
                .overlay(alignment: .top) { divider }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignTokens.Colors.surface2)
            .frame(height: Det.borderWidth)
    }

    // MARK: - 月相行

    private var moonRow: some View {
        HStack(spacing: 0) {
            Text("MOON")
                .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                .tracking(Det.labelTracking)
                .foregroundStyle(DesignTokens.Colors.secondary)
            Spacer(minLength: 0)
            HStack(spacing: Det.moonGap) {
                ForEach(Array(data.moonStrip.enumerated()), id: \.offset) { _, item in
                    MoonGlyph(age: item.age, size: Det.moonGlyphSize, radius: Det.moonGlyphRadius)
                        .overlay {
                            if item.isToday {
                                Circle().stroke(DesignTokens.Colors.orange, lineWidth: Det.moonTodayBorder)
                            }
                        }
                        .opacity(item.isToday ? 1 : Det.moonOtherOpacity)
                }
            }
        }
        .padding(.top, Det.moonRowPadTop)
        .padding(.bottom, Det.moonRowPadBottom)
        .overlay(alignment: .top) { divider }
    }

    // MARK: - 内訳

    private var breakdown: some View {
        VStack(spacing: Det.breakdownGap) {
            ForEach(data.score.components) { component in
                HStack(spacing: Det.breakdownGap) {
                    Text(component.key.rawValue)
                        .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .frame(width: Det.breakdownLabelWidth, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Det.breakdownBarRadius, style: .continuous)
                                .fill(DesignTokens.Colors.surface2)
                            RoundedRectangle(cornerRadius: Det.breakdownBarRadius, style: .continuous)
                                .fill(component.barFraction >= Det.breakdownOrangeThreshold
                                      ? DesignTokens.Colors.orange : DesignTokens.Colors.primary)
                                .frame(width: proxy.size.width * min(component.barFraction, 1))
                        }
                    }
                    .frame(height: Det.breakdownBarHeight)
                    Text("+\(component.points)")
                        .font(DesignTokens.Fonts.text(Det.breakdownValueFontSize, .w500))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .frame(width: Det.breakdownValueWidth, alignment: .trailing)
                }
            }
            fetchedRow
        }
        .padding(.top, Det.breakdownPadTop)
        .overlay(alignment: .top) { divider }
    }

    /// 取得時刻と由来（指示書 §4: オフライン時はキャッシュを表示し、取得時刻を Detail に出す）。
    private var fetchedRow: some View {
        HStack(spacing: Det.breakdownGap) {
            Text("DATA")
                .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.secondary)
                .frame(width: Det.breakdownLabelWidth, alignment: .leading)
            Text(data.fetchedAt.map { TimeFormat.monthDayTime.string(from: $0) } ?? "—")
                .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.secondary)
            Spacer(minLength: 0)
            Text(data.sources.joined(separator: " / "))
                .font(DesignTokens.Fonts.text(Det.labelFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
    }
}

#Preview {
    let now = Date()
    let point = GeoPoint(latitude: 35.1352, longitude: 139.6079)
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = Tide736.timeZone
    let day = MockTideProvider.synthesize(dayStart: cal.startOfDay(for: now), point: point,
                                          timeZone: Tide736.timeZone, fetchedAt: now)
    let weather = WeatherSnapshot(windSpeed: 4.2, windDirection: 45, pressure: 1009, pressureTrend3h: -3,
                                  airTemperature: 16.8, validAt: now, fetchedAt: now)
    let marine = MarineSnapshot(waveHeight: 0.6, wavePeriod: 7, swellHeight: 0.4, swellDirection: 160,
                                seaSurfaceTemperature: 19.2, validAt: now, fetchedAt: now)
    let score = FishingScore.compute(FishingScore.input(at: now, tide: day, weather: weather, marine: marine,
                                                        band: Species.defaultForScore.band))
    return DetailView(data: DetailData.make(spotName: "城ヶ島 西側", now: now, day: day, weather: weather, marine: marine,
                                            score: score, weatherSource: "mock", marineSource: "mock"))
}
