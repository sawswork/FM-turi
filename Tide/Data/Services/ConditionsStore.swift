import Foundation
import Observation
import OSLog
import SwiftData
import TideCore

/// 気象（WeatherKit）と海況（Open-Meteo Marine）の取得とキャッシュ。
/// 同一地点（0.01°）・同一時刻（1時間）のキーが SwiftData にあれば再取得しない。
@MainActor
@Observable
final class ConditionsStore {
    private(set) var weather: WeatherSnapshot?
    private(set) var marine: MarineSnapshot?
    /// 取得できた範囲の時間ごとの海況（前日〜3日先）。
    private(set) var marineSeries: [MarineSnapshot] = []
    private(set) var isLoading = false
    private(set) var weatherSource: String?
    private(set) var marineSource: String?

    private let context: ModelContext
    private let weatherProvider: any WeatherProvider
    private let marineProvider: any MarineProvider
    private let fallbackWeather: any WeatherProvider
    private let fallbackMarine: any MarineProvider
    private let logger = Logger(subsystem: "jp.tide.app", category: "Conditions")

    init(context: ModelContext,
         weatherProvider: any WeatherProvider,
         marineProvider: any MarineProvider,
         fallbackWeather: any WeatherProvider = MockWeatherProvider(),
         fallbackMarine: any MarineProvider = MockMarineProvider()) {
        self.context = context
        self.weatherProvider = weatherProvider
        self.marineProvider = marineProvider
        self.fallbackWeather = fallbackWeather
        self.fallbackMarine = fallbackMarine
    }

    /// 本番構成。シミュレータでは固定値モック（指示書 §2）。
    static func live(context: ModelContext) -> ConditionsStore {
        #if targetEnvironment(simulator)
        return ConditionsStore(context: context, weatherProvider: MockWeatherProvider(),
                               marineProvider: MockMarineProvider())
        #else
        return ConditionsStore(context: context, weatherProvider: WeatherKitProvider(),
                               marineProvider: OpenMeteoMarineProvider())
        #endif
    }

    func load(point: GeoPoint, at date: Date = Date()) async {
        isLoading = true
        defer { isLoading = false }
        await loadWeather(point: point, at: date)
        await loadMarine(point: point, at: date)
    }

    // MARK: - Weather

    private func loadWeather(point: GeoPoint, at date: Date) async {
        let key = CacheKey.make(point: point, date: date)
        if let cached = weatherRecord(key: key) {
            weather = cached.snapshot
            weatherSource = cached.source
            return
        }
        do {
            let snapshot = try await weatherProvider.weather(at: point, for: date)
            store(snapshot, key: key, point: point, source: Self.sourceName(weatherProvider))
        } catch {
            logger.notice("気象の取得に失敗、退避: \(error.localizedDescription, privacy: .public)")
            if let latest = latestWeatherRecord(near: point) {
                weather = latest.snapshot
                weatherSource = latest.source
            } else if let snapshot = try? await fallbackWeather.weather(at: point, for: date) {
                store(snapshot, key: key, point: point, source: Self.sourceName(fallbackWeather))
            }
        }
    }

    private func store(_ snapshot: WeatherSnapshot, key: String, point: GeoPoint, source: String) {
        let record = WeatherRecord(key: key, point: point.rounded, snapshot: snapshot, source: source)
        context.insert(record)
        save()
        weather = snapshot
        weatherSource = source
    }

    private func weatherRecord(key: String) -> WeatherRecord? {
        var descriptor = FetchDescriptor<WeatherRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func latestWeatherRecord(near point: GeoPoint) -> WeatherRecord? {
        let rounded = point.rounded
        let lat = rounded.latitude
        let lon = rounded.longitude
        var descriptor = FetchDescriptor<WeatherRecord>(
            predicate: #Predicate { $0.latitude == lat && $0.longitude == lon },
            sortBy: [SortDescriptor(\.validAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Marine

    private func loadMarine(point: GeoPoint, at date: Date) async {
        let key = CacheKey.make(point: point, date: date)
        if marineRecord(key: key) == nil {
            do {
                let rows = try await marineProvider.marine(at: point, around: date)
                storeMarine(rows, point: point, source: Self.sourceName(marineProvider))
            } catch {
                logger.notice("海況の取得に失敗、退避: \(error.localizedDescription, privacy: .public)")
                if marineSeries(near: point, around: date).isEmpty,
                   let rows = try? await fallbackMarine.marine(at: point, around: date) {
                    storeMarine(rows, point: point, source: Self.sourceName(fallbackMarine))
                }
            }
        }
        let series = marineSeries(near: point, around: date)
        marineSeries = series.map(\.snapshot)
        let bucket = CacheKey.bucketStart(date)
        let current = series.first { $0.validAt == bucket } ?? series.min {
            abs($0.validAt.timeIntervalSince(date)) < abs($1.validAt.timeIntervalSince(date))
        }
        marine = current?.snapshot
        marineSource = current?.source
    }

    private func storeMarine(_ rows: [MarineSnapshot], point: GeoPoint, source: String) {
        let rounded = point.rounded
        for row in rows {
            let rowKey = CacheKey.make(point: rounded, date: row.validAt)
            guard marineRecord(key: rowKey) == nil else { continue }
            context.insert(MarineRecord(key: rowKey, point: rounded, snapshot: row, source: source))
        }
        save()
    }

    private func marineRecord(key: String) -> MarineRecord? {
        var descriptor = FetchDescriptor<MarineRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func marineSeries(near point: GeoPoint, around date: Date) -> [MarineRecord] {
        let rounded = point.rounded
        let lat = rounded.latitude
        let lon = rounded.longitude
        let from = CacheKey.bucketStart(date).addingTimeInterval(-36 * 3600)
        let to = CacheKey.bucketStart(date).addingTimeInterval(72 * 3600)
        let descriptor = FetchDescriptor<MarineRecord>(
            predicate: #Predicate {
                $0.latitude == lat && $0.longitude == lon && $0.validAt >= from && $0.validAt <= to
            },
            sortBy: [SortDescriptor(\.validAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Helpers

    private func save() {
        do {
            try context.save()
        } catch {
            logger.error("保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func sourceName(_ provider: Any) -> String {
        switch provider {
        case is MockWeatherProvider, is MockMarineProvider: "mock"
        case is OpenMeteoMarineProvider: "open-meteo"
        default: "weatherkit"
        }
    }
}
