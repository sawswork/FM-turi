@testable import TideCore
import XCTest

final class OpenMeteoMarineTests: XCTestCase {
    let fixture = """
    {
      "latitude": 35.125, "longitude": 139.625, "utc_offset_seconds": 0, "timezone": "UTC",
      "hourly_units": {"time": "unixtime", "wave_height": "m"},
      "hourly": {
        "time": [1792000800, 1792004400, 1792008000],
        "wave_height": [0.6, 0.7, null],
        "wave_period": [7.0, 7.2, 7.5],
        "swell_wave_height": [0.4, 0.45, 0.5],
        "swell_wave_direction": [160, 162, 165],
        "sea_surface_temperature": [19.2, 19.3, 19.4]
      }
    }
    """

    func testParsesHourlyRows() throws {
        let fetched = Date()
        let rows = try OpenMeteoMarine.parse(Data(fixture.utf8), fetchedAt: fetched)
        XCTAssertEqual(rows.count, 2, "null の時間は捨てる")
        XCTAssertEqual(rows[0].waveHeight, 0.6)
        XCTAssertEqual(rows[0].wavePeriod, 7.0)
        XCTAssertEqual(rows[0].seaSurfaceTemperature, 19.2)
        XCTAssertEqual(rows[0].validAt, Date(timeIntervalSince1970: 1_792_000_800))
        XCTAssertEqual(rows[1].swellDirection, 162)
        XCTAssertEqual(rows[1].fetchedAt, fetched)
    }

    func testEmptyIsError() {
        let json = #"{"hourly":{"time":[],"wave_height":[],"wave_period":[],"swell_wave_height":[],"swell_wave_direction":[],"sea_surface_temperature":[]}}"#
        XCTAssertThrowsError(try OpenMeteoMarine.parse(Data(json.utf8), fetchedAt: Date()))
    }

    func testRequestURL() throws {
        let url = OpenMeteoMarine.requestURL(for: GeoPoint(latitude: 35.1345, longitude: 139.6155))
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(url.host, "marine-api.open-meteo.com")
        XCTAssertEqual(query.first { $0.name == "latitude" }?.value, "35.1345")
        XCTAssertEqual(query.first { $0.name == "timeformat" }?.value, "unixtime")
        XCTAssertTrue(query.first { $0.name == "hourly" }?.value?.contains("sea_surface_temperature") == true)
    }

    func testCompassLabel() {
        XCTAssertEqual(WeatherSnapshot.compassLabel(degrees: 45), "NE")
        XCTAssertEqual(WeatherSnapshot.compassLabel(degrees: 0), "N")
        XCTAssertEqual(WeatherSnapshot.compassLabel(degrees: 359), "N")
        XCTAssertEqual(WeatherSnapshot.compassLabel(degrees: 180), "S")
        XCTAssertEqual(WeatherSnapshot.compassLabel(degrees: 292.5), "WNW")
    }

    func testMockProvidersReturnSpecValues() async throws {
        let point = GeoPoint(latitude: 35.1345, longitude: 139.6155)
        let weather = try await MockWeatherProvider().weather(at: point, for: Date())
        XCTAssertEqual(weather.windSpeed, 4.2)
        XCTAssertEqual(weather.compassLabel, "NE")
        XCTAssertEqual(weather.pressure, 1009)
        XCTAssertEqual(weather.pressureTrend3h, -3)
        let marine = try await MockMarineProvider().marine(at: point, around: Date())
        XCTAssertEqual(marine.count, 72)
        XCTAssertEqual(marine.first?.waveHeight, 0.6)
        XCTAssertEqual(marine.first?.seaSurfaceTemperature, 19.2)
    }
}
