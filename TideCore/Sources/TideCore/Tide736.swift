import Foundation

/// tide736.net 潮汐API（https://tide736.net）の URL 生成と解析。
/// 応答: tide.chart["yyyy-MM-dd"] = { tide:[{time,unix(ms),cm}] 20分刻み73点, flood:[満潮], edd:[干潮],
///       sun:{rise,set,...}, moon:{age,title,brightness,...} }
public enum Tide736 {
    public static let baseURL = URL(string: "https://tide736.net/api/get_tide.php")!
    /// tide736 は日本の港のみ。時刻はすべて JST。
    public static let timeZone = TimeZone(identifier: "Asia/Tokyo")!

    public struct Port: Hashable, Codable, Sendable {
        /// 都道府県コード
        public var pc: Int
        /// 港コード
        public var hc: Int
        public var name: String
        public var lat: Double
        public var lon: Double

        public var point: GeoPoint { GeoPoint(latitude: lat, longitude: lon) }
        /// キャッシュキー等に使う識別子 "14-13"
        public var code: String { "\(pc)-\(hc)" }

        public init(pc: Int, hc: Int, name: String, lat: Double, lon: Double) {
            self.pc = pc
            self.hc = hc
            self.name = name
            self.lat = lat
            self.lon = lon
        }
    }

    public enum ParseError: Error, Equatable {
        case badStatus(Int)
        case noChart
    }

    /// 1日分の URL（rg=day）。
    public static func requestURL(port: Port, dayStart: Date) -> URL {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: dayStart)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "pc", value: String(port.pc)),
            URLQueryItem(name: "hc", value: String(port.hc)),
            URLQueryItem(name: "yr", value: String(comps.year ?? 2000)),
            URLQueryItem(name: "mn", value: String(comps.month ?? 1)),
            URLQueryItem(name: "dy", value: String(comps.day ?? 1)),
            URLQueryItem(name: "rg", value: "day")
        ]
        return components.url!
    }

    // MARK: - 解析

    struct Response: Decodable {
        var status: Int
        var tide: TideBody?

        struct TideBody: Decodable {
            var chart: [String: Day]
        }

        struct Day: Decodable {
            var tide: [Point]
            var flood: [Point]?
            var edd: [Point]?
            var sun: Sun?
            var moon: Moon?
        }

        struct Point: Decodable {
            var time: String
            var unix: Double
            var cm: Double
        }

        struct Sun: Decodable {
            var rise: String?
            var set: String?
        }

        struct Moon: Decodable {
            var age: String?
            var title: String?
            var brightness: String?
        }
    }

    /// JSON → 日ごとの TideDay（日付順）。
    public static func parse(_ data: Data, fetchedAt: Date) throws -> [TideDay] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.status == 1 else { throw ParseError.badStatus(response.status) }
        guard let chart = response.tide?.chart, !chart.isEmpty else { throw ParseError.noChart }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var days: [TideDay] = []
        for key in chart.keys.sorted() {
            guard let day = chart[key], day.tide.count >= 2 else { continue }
            let points = day.tide.sorted { $0.unix < $1.unix }
            let dayStart = Date(timeIntervalSince1970: points[0].unix / 1000)
            let interval = (points[1].unix - points[0].unix) / 1000
            let levels = points.map(\.cm)
            let highs = (day.flood ?? []).map { TideExtreme(time: Date(timeIntervalSince1970: $0.unix / 1000), heightCm: $0.cm) }
            let lows = (day.edd ?? []).map { TideExtreme(time: Date(timeIntervalSince1970: $0.unix / 1000), heightCm: $0.cm) }
            let sunrise = time(day.sun?.rise, on: dayStart, calendar: cal)
            let sunset = time(day.sun?.set, on: dayStart, calendar: cal)
            let age = Double(day.moon?.age ?? "") ?? MoonCalc.age(at: dayStart.addingTimeInterval(12 * 3600))
            let tideType = TideType(label: day.moon?.title ?? "") ?? MoonCalc.tideType(age: age)
            days.append(TideDay(dayStart: dayStart, levels: levels, interval: interval, highs: highs, lows: lows,
                                sunrise: sunrise, sunset: sunset, moonAge: age, tideType: tideType,
                                fetchedAt: fetchedAt, source: "tide736"))
        }
        guard !days.isEmpty else { throw ParseError.noChart }
        return days
    }

    /// "HH:MM" → その日の時刻。
    static func time(_ text: String?, on dayStart: Date, calendar: Calendar) -> Date? {
        guard let text else { return nil }
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return calendar.date(byAdding: .minute, value: parts[0] * 60 + parts[1], to: dayStart)
    }

    // MARK: - 港一覧（同梱）

    /// 同梱の港一覧（tide736 の link 情報から生成。座標は度分→十進に変換済み）。
    public static let ports: [Port] = {
        guard let url = Bundle.module.url(forResource: "tide736_ports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Port].self, from: data) else {
            return []
        }
        return list
    }()

    /// 最寄りの港。
    public static func nearestPort(to point: GeoPoint, in list: [Port] = ports) -> Port? {
        list.min { $0.point.distance(to: point) < $1.point.distance(to: point) }
    }
}
