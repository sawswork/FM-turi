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
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let dayStart = cal.startOfDay(for: now)
        let station = Tide736.nearestPort(to: point)
        let code = station?.code ?? "none"
        stationName = station?.name
        let keys = (0..<Self.dayCount).map { index in
            TideDayRecord.key(stationCode: code, dayStart: dayStart.addingTimeInterval(TimeInterval(index) * 86_400), timeZone: timeZone)
        }
        let cached = keys.compactMap { record(key: $0)?.day }
        if cached.count == keys.count {
            days = cached
            return
        }
        do {
            let fetched = try await provider.tide(at: point, from: dayStart, days: Self.dayCount, timeZone: timeZone)
            store(fetched, code: code, timeZone: timeZone)
            days = fetched
        } catch {
            logger.notice("潮汐の取得に失敗、退避: \(error.localizedDescription, privacy: .public)")
            if let fetched = try? await fallback.tide(at: point, from: dayStart, days: Self.dayCount, timeZone: timeZone) {
                store(fetched, code: code, timeZone: timeZone)
                days = fetched
            }
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
}
