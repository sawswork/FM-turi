import Foundation
import TideCore

/// Detail シートに出す値。Home のストアから組み立てる。
struct DetailData: Equatable {
    var spotName: String
    var date: Date
    var score: FishingScore.Result
    var tideLevelCm: Double?
    var isRising: Bool?
    var tideType: TideType?
    var weather: WeatherSnapshot?
    var marine: MarineSnapshot?
    var sunrise: Date?
    var sunset: Date?
    var highs: [Date]
    var lows: [Date]
    var moonAge: Double?
    var fetchedAt: Date?
    var sources: [String]

    static func make(spotName: String, now: Date, day: TideDay?, weather: WeatherSnapshot?, marine: MarineSnapshot?,
                     score: FishingScore.Result, weatherSource: String?, marineSource: String?) -> DetailData {
        var sources: [String] = []
        if let weatherSource { sources.append(weatherSource) }
        if let marineSource, !sources.contains(marineSource) { sources.append(marineSource) }
        if let source = day?.source, !sources.contains(source) { sources.append(source) }
        let fetched = [weather?.fetchedAt, marine?.fetchedAt, day?.fetchedAt].compactMap { $0 }.max()
        return DetailData(
            spotName: spotName, date: now, score: score,
            tideLevelCm: day?.level(at: now), isRising: day?.isRising(at: now), tideType: day?.tideType,
            weather: weather, marine: marine, sunrise: day?.sunrise, sunset: day?.sunset,
            highs: day?.highs.map(\.time) ?? [], lows: day?.lows.map(\.time) ?? [],
            moonAge: day?.moonAge, fetchedAt: fetched, sources: sources
        )
    }

    /// Detail 月相行の7つ（ADR-0005）: 今日より前の節目（最大3）→ 今日 → 明日 → 今日より後の節目。
    var moonStrip: [(age: Double, isToday: Bool)] {
        let today = moonAge ?? 0
        let milestones = [0.0, 3.7, 7.4, 14.8, 22.1]
        let before = milestones.filter { $0 < today - 0.5 }.suffix(3)
        let afterCandidates = milestones.filter { $0 > today + 1.5 }
        var strip: [(Double, Bool)] = before.map { ($0, false) }
        strip.append((today, true))
        strip.append((today + 1, false))
        let needed = DesignTokens.Detail.moonCount - strip.count
        strip.append(contentsOf: afterCandidates.prefix(max(needed, 0)).map { ($0, false) })
        while strip.count < DesignTokens.Detail.moonCount {
            strip.append(((strip.last?.0 ?? today) + 3.7, false))
        }
        return strip.map { (age: $0.0, isToday: $0.1) }
    }
}
