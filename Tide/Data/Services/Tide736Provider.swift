import Foundation
import TideCore

/// tide736 実装。日ごとに1リクエスト。
struct Tide736Provider: TideProvider {
    var session: URLSession = .shared

    func tide(at point: GeoPoint, from dayStart: Date, days: Int, timeZone: TimeZone) async throws -> [TideDay] {
        guard let port = Tide736.nearestPort(to: point) else { throw Tide736.ParseError.noChart }
        return try await fetch(port: port, from: dayStart, days: days)
    }

    /// 港を指定して日ごとに取得（調和定数の当てはめ用にも使う）。
    func fetch(port: Tide736.Port, from dayStart: Date, days: Int) async throws -> [TideDay] {
        var result: [TideDay] = []
        for index in 0..<days {
            let start = dayStart.addingTimeInterval(TimeInterval(index) * 86_400)
            var request = URLRequest(url: Tide736.requestURL(port: port, dayStart: start))
            request.timeoutInterval = 15
            request.setValue("Tide iOS", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            result.append(contentsOf: try Tide736.parse(data, fetchedAt: Date()))
        }
        return result
    }
}
