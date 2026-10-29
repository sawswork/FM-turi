@testable import TideCore
import XCTest

final class Tide736Tests: XCTestCase {
    // 2026-10-30 城ヶ島（プローブで確認した実応答の形）。tide は 20 分刻みのうち先頭4点と末尾2点。
    let fixture = """
    {"status":1,"message":"正常終了","tide":{"port":{"prefecture_code":14,"harbor_code":13,"harbor_namej":"城ヶ島"},
    "chart":{"2026-10-30":{
      "sun":{"astro_twilight":["04:35","18:15"],"regular_twilight":["05:34","17:16"],
             "rise":"06:00","midline":"11:25","set":"16:50"},
      "moon":{"brightness":"79.5","age":"19.5","title":"中潮","rise":"29日 19:00",
              "midline":"30日 02:46","set":"30日 10:32","name":null},
      "flood":[{"time":"07:55","unix":1793314500000,"cm":139.7},{"time":"18:04","unix":1793351040000,"cm":152.7}],
      "edd":[{"time":"00:47","unix":1793288820000,"cm":12.2},{"time":"12:41","unix":1793331660000,"cm":103.9}],
      "tide":[{"time":"00:00","unix":1793286000000,"cm":16.6},{"time":"00:20","unix":1793287200000,"cm":13.7},
              {"time":"00:40","unix":1793288400000,"cm":12.3},{"time":"01:00","unix":1793289600000,"cm":12.5}]
    }}}}
    """
    let jst = TimeZone(identifier: "Asia/Tokyo")!

    func testParse() throws {
        let fetched = Date()
        let days = try Tide736.parse(Data(fixture.utf8), fetchedAt: fetched)
        XCTAssertEqual(days.count, 1)
        let day = days[0]
        XCTAssertEqual(day.dayStart, Date(timeIntervalSince1970: 1_793_286_000))
        XCTAssertEqual(day.interval, 1200)
        XCTAssertEqual(day.levels, [16.6, 13.7, 12.3, 12.5])
        XCTAssertEqual(day.highs.map(\.heightCm), [139.7, 152.7])
        XCTAssertEqual(day.lows.first?.time, Date(timeIntervalSince1970: 1_793_288_820))
        XCTAssertEqual(day.moonAge, 19.5)
        XCTAssertEqual(day.tideType, .middle)
        XCTAssertEqual(day.source, "tide736")
        XCTAssertEqual(day.fetchedAt, fetched)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = jst
        let rise = cal.dateComponents([.hour, .minute], from: try XCTUnwrap(day.sunrise))
        XCTAssertEqual(rise.hour, 6)
        XCTAssertEqual(rise.minute, 0)
        let set = cal.dateComponents([.hour, .minute], from: try XCTUnwrap(day.sunset))
        XCTAssertEqual(set.hour, 16)
        XCTAssertEqual(set.minute, 50)
        // 00:10 の補間
        XCTAssertEqual(try XCTUnwrap(day.level(at: day.dayStart.addingTimeInterval(600))), 15.15, accuracy: 0.001)
    }

    func testBadStatus() {
        let json = #"{"status":0,"message":"error"}"#
        XCTAssertThrowsError(try Tide736.parse(Data(json.utf8), fetchedAt: Date()))
    }

    func testRequestURL() throws {
        let port = Tide736.Port(pc: 14, hc: 13, name: "城ヶ島", lat: 35.1333, lon: 139.6167)
        let url = Tide736.requestURL(port: port, dayStart: Date(timeIntervalSince1970: 1_793_286_000))
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        func value(_ name: String) -> String? { query.first { $0.name == name }?.value }
        XCTAssertEqual(url.host, "tide736.net")
        XCTAssertEqual(value("pc"), "14")
        XCTAssertEqual(value("hc"), "13")
        XCTAssertEqual(value("yr"), "2026")
        XCTAssertEqual(value("mn"), "10")
        XCTAssertEqual(value("dy"), "30")
        XCTAssertEqual(value("rg"), "day")
    }

    func testBundledPortsAndNearest() throws {
        XCTAssertGreaterThan(Tide736.ports.count, 700)
        let nearest = try XCTUnwrap(Tide736.nearestPort(to: GeoPoint(latitude: 35.1352, longitude: 139.6079)))
        XCTAssertEqual(nearest.name, "城ヶ島")
        XCTAssertEqual(nearest.code, "14-13")
    }
}
