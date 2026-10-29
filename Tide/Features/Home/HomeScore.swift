import Foundation
import SwiftUI
import TideCore

/// Home に出す釣れ率と4条件メーターの値（ADR-0005）。
struct HomeScore {
    let result: FishingScore.Result
    /// 選択中の日の毎正時の釣れ率（24個）
    let hourly: [Int]
    let weather: WeatherSnapshot?
    let marine: MarineSnapshot?

    static func make(now: Date, day: TideDay?, selectedDay: TideDay?, weather: WeatherSnapshot?,
                     marine: MarineSnapshot?, marineSeries: [MarineSnapshot], band: TemperatureBand?) -> HomeScore {
        let input = FishingScore.input(at: now, tide: day, weather: weather, marine: marine, band: band)
        let result = FishingScore.compute(input)
        let hourly = selectedDay.map {
            FishingScore.hourlyTotals(day: $0, weather: weather, marineSeries: marineSeries, band: band)
        } ?? Array(repeating: 0, count: 24)
        return HomeScore(result: result, hourly: hourly, weather: weather, marine: marine)
    }

    /// 4条件メーター（wind / wave / drop / pressure）の割合と色。
    struct Meter: Identifiable {
        let icon: TideIcon
        let fraction: Double
        let color: Color
        let rotation: Angle
        var id: String { "\(icon)" }
    }

    var meters: [Meter] {
        let windSpeed = weather?.windSpeed ?? 0
        let windFraction = min(windSpeed / FishingScore.windZeroSpeed, 1)
        let waveHeight = marine?.waveHeight ?? 0
        let waveFraction = min(waveHeight / FishingScore.waveZeroHeight, 1)
        let sstFraction = Double(result.component(.sst).points) / Double(FishingScore.Key.sst.max)
        let trend = weather?.pressureTrend3h ?? 0
        let pressureFraction = min(abs(trend) / (2 * FishingScore.pressureSpan), 1)
        return [
            Meter(icon: .wind, fraction: windFraction,
                  color: windFraction >= 0.5 ? DesignTokens.Colors.orange : DesignTokens.Colors.primary,
                  rotation: .degrees(((weather?.windDirection ?? 40) + 180).truncatingRemainder(dividingBy: 360))),
            Meter(icon: .wave, fraction: waveFraction,
                  color: waveFraction >= 0.5 ? DesignTokens.Colors.orange : DesignTokens.Colors.primary,
                  rotation: .zero),
            Meter(icon: .drop, fraction: sstFraction,
                  color: sstFraction >= 0.5 ? DesignTokens.Colors.green : DesignTokens.Colors.primary,
                  rotation: .zero),
            Meter(icon: .pressure, fraction: pressureFraction,
                  color: trend < 0 ? DesignTokens.Colors.green : DesignTokens.Colors.primary,
                  rotation: .zero)
        ]
    }
}
