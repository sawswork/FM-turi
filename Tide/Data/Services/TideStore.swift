import Foundation
import Observation
import OSLog
import SwiftData
import TideCore

/// 潮汐（3日分）の取得とキャッシュ。港×日のキーが SwiftData にあれば再取得しない。
@MainActor
@Observable
final class TideStore {
    /// 今日から3日分（現地0時起点）。
    private(set) var days: [TideDay] = []
    private(set) var stationName: String?
    private(set) var isLoading = false

    static let dayCount = 3

    private let context: ModelContext
    private let provider: any TideProvider
    private let fallback: any TideProvider
    private let logger = Logger(subsystem: "jp.tide.app", category: "Tide")
    /// 当てはめ中の港コード（重複実行の防止）
    private var fittingStations: Set<String> = []

    init(context: ModelContext, provider: any TideProvider, fallback: any TideProvider = MockTideProvider()) {
        self.context = context
        self.provider = provider
        self.fallback = fallback
    }

    static func live(context: ModelContext) -> TideStore {
        #if targetEnvironment(simulator)
        return TideStore(context: context, provider: MockTideProvider())
        #else
        return TideStore(context: context, provider: Tide736Provider())
        #endif
    }

    /// 今日の潮汐。
    var today: TideDay? { days.first }

    func load(point: GeoPoint, now: Date = Date(), timeZone: TimeZone = Tide736.timeZone) async {
        isLoading = true
        defer { isLoading = false }
        let result = await days(for: point, now: now, timeZone: timeZone)
        stationName = result.stationName
        days = result.days
    }

    /// 任意地点の潮汐（キャッシュ優先）。画面の状態は変えない。
    func days(for point: GeoPoint, now: Date = Date(),
              timeZone: TimeZone = Tide736.timeZone) async -> (days: [TideDay], stationName: String?) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let dayStart = cal.startOfDay(for: now)
        let station = Tide736.nearestPort(to: point)
        let code = station?.code ?? "none"
        // M3: 調和定数があれば端末内で計算（通信なし）
        if let station, let constants = constants(for: code) {
            let days = (0..<Self.dayCount).map { index in
                HarmonicTide.day(starting: dayStart.addingTimeInterval(TimeInterval(index) * 86_400),
                                 constants: constants, point: station.point, timeZone: timeZone, now: now)
            }
            return (days, station.name)
        }
        let keys = (0..<Self.dayCount).map { index in
            TideDayRecord.key(stationCode: code, dayStart: dayStart.addingTimeInterval(TimeInterval(index) * 86_400), timeZone: timeZone)
        }
        let cached = keys.compactMap { record(key: $0)?.day }
        if cached.count == keys.count {
            scheduleFit(station: station, dayStart: dayStart, timeZone: timeZone)
            return (cached, station?.name)
        }
        do {
            let fetched = try await provider.tide(at: point, from: dayStart, days: Self.dayCount, timeZone: timeZone)
            store(fetched, code: code, timeZone: timeZone)
            scheduleFit(station: station, dayStart: dayStart, timeZone: timeZone)
            return (fetched, station?.name)
        } catch {
            logger.notice("潮汐の取得に失敗、退避: \(error.localizedDescription, privacy: .public)")
            if let fetched = try? await fallback.tide(at: point, from: dayStart, days: Self.dayCount, timeZone: timeZone) {
                store(fetched, code: code, timeZone: timeZone)
                return (fetched, station?.name)
            }
            return ([], station?.name)
        }
    }

    private func store(_ fetched: [TideDay], code: String, timeZone: TimeZone) {
        for day in fetched {
            let key = TideDayRecord.key(stationCode: code, dayStart: day.dayStart, timeZone: timeZone)
            guard record(key: key) == nil else { continue }
            context.insert(TideDayRecord(key: key, stationCode: code, day: day))
        }
        do {
            try context.save()
        } catch {
            logger.error("潮汐の保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func record(key: String) -> TideDayRecord? {
        var descriptor = FetchDescriptor<TideDayRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - 調和定数（M3）

    private func constants(for code: String) -> HarmonicTide.Constants? {
        var descriptor = FetchDescriptor<TideStationConstants>(predicate: #Predicate { $0.stationCode == code })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.constants
    }

    /// 港の 30 日分を取得して調和定数を当てはめ、保存する（バックグラウンド、1回だけ）。
    private func scheduleFit(station: Tide736.Port?, dayStart: Date, timeZone: TimeZone) {
        guard let station, let fetcher = provider as? Tide736Provider, !fittingStations.contains(station.code) else { return }
        fittingStations.insert(station.code)
        Task { [weak self] in
            defer { self?.fittingStations.remove(station.code) }
            guard let self else { return }
            do {
                let from = dayStart.addingTimeInterval(-7 * 86_400)
                let days = try await fetcher.fetch(port: station, from: from, days: TideStationConstants.fitDays)
                let samples = days.flatMap { day in
                    day.levels.enumerated().map { index, level in
                        (date: day.dayStart.addingTimeInterval(TimeInterval(index) * day.interval), levelCm: level)
                    }
                }
                let constants = try HarmonicTide.fit(samples: samples)
                guard constants.rmsErrorCm <= TideStationConstants.maxRmsErrorCm else {
                    logger.notice("調和定数の残差が大きいため採用しない: \(constants.rmsErrorCm, privacy: .public) cm")
                    return
                }
                context.insert(TideStationConstants(stationCode: station.code, constants: constants))
                try context.save()
                logger.notice("調和定数を保存: \(station.code, privacy: .public) rms=\(constants.rmsErrorCm, privacy: .public)")
            } catch {
                logger.notice("調和定数の当てはめに失敗: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
