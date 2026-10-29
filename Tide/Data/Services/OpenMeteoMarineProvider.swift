import Foundation
import TideCore

/// Open-Meteo Marine API 実装。解析は TideCore.OpenMeteoMarine。
struct OpenMeteoMarineProvider: MarineProvider {
    var session: URLSession = .shared

    func marine(at point: GeoPoint, around date: Date) async throws -> [MarineSnapshot] {
        var request = URLRequest(url: OpenMeteoMarine.requestURL(for: point))
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try OpenMeteoMarine.parse(data, fetchedAt: Date())
    }
}
