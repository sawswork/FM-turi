@testable import Tide
import SwiftData
import TideCore
import XCTest

actor CallCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

struct CountingWeatherProvider: WeatherProvider {
    let counter: CallCounter
    func weather(at point: GeoPoint, for date: Date) async throws -> WeatherSnapshot {
        await counter.increment()
        return try await MockWeatherProvider().weather(at: point, for: date)
    }
}

struct CountingMarineProvider: MarineProvider {
    let counter: CallCounter
    func marine(at point: GeoPoint, around date: Date) async throws -> [MarineSnapshot] {
        await counter.increment()
        return try await MockMarineProvider().marine(at: point, around: date)
    }
}

@MainActor
final class ConditionsStoreTests: XCTestCase {
    func testSamePointSameHourDoesNotRefetch() async throws {
        let container = try AppContainer.makeInMemory()
        let weatherCalls = CallCounter()
        let marineCalls = CallCounter()
        let store = ConditionsStore(context: container.mainContext,
                                    weatherProvider: CountingWeatherProvider(counter: weatherCalls),
                                    marineProvider: CountingMarineProvider(counter: marineCalls))
        let point = GeoPoint(latitude: 35.1352, longitude: 139.6079)
        let date = CacheKey.bucketStart(Date()).addingTimeInterval(600)

        await store.load(point: point, at: date)
        XCTAssertEqual(store.weather?.windSpeed, 4.2)
        XCTAssertEqual(store.marine?.waveHeight, 0.6)
        let weatherAfterFirst = await weatherCalls.count
        let marineAfterFirst = await marineCalls.count
        XCTAssertEqual(weatherAfterFirst, 1)
        XCTAssertEqual(marineAfterFirst, 1)

        // 同一地点（0.01° 内）・同一時間帯 → 再取得しない
        let nearby = GeoPoint(latitude: point.latitude + 0.003, longitude: point.longitude - 0.002)
        await store.load(point: nearby, at: date.addingTimeInterval(1200))
        let weatherAfterSecond = await weatherCalls.count
        let marineAfterSecond = await marineCalls.count
        XCTAssertEqual(weatherAfterSecond, 1)
        XCTAssertEqual(marineAfterSecond, 1)

        // 別インスタンスでも SwiftData のキャッシュが効く
        let store2 = ConditionsStore(context: container.mainContext,
                                     weatherProvider: CountingWeatherProvider(counter: weatherCalls),
                                     marineProvider: CountingMarineProvider(counter: marineCalls))
        await store2.load(point: point, at: date)
        let weatherAfterThird = await weatherCalls.count
        XCTAssertEqual(weatherAfterThird, 1)
        XCTAssertEqual(store2.weatherSource, "weatherkit")

        // 別の時間帯 → 気象は再取得、海況は時系列キャッシュ内なので再取得しない
        await store.load(point: point, at: date.addingTimeInterval(3600))
        let weatherAfterNextHour = await weatherCalls.count
        let marineAfterNextHour = await marineCalls.count
        XCTAssertEqual(weatherAfterNextHour, 2)
        XCTAssertEqual(marineAfterNextHour, 1)
    }
}
