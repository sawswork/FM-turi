import Foundation
import MapKit
import Observation
import OSLog
import SwiftData
import TideCore

/// 釣り場候補の検索（MKLocalSearch＋tide736 港）とキャッシュ、各釣り場の釣れ率。
@MainActor
@Observable
final class SpotsStore {
    static let keywords = ["漁港", "堤防", "岬", "磯", "港"]

    /// 釣り場 id → 釣れ率
    private(set) var scores: [UUID: Int] = [:]
    /// 釣り場 id → 風向（度）
    private(set) var windDirections: [UUID: Double] = [:]
    private(set) var isSearching = false
    private(set) var lastSearchCenter: GeoPoint?

    private let context: ModelContext
    private let logger = Logger(subsystem: "jp.tide.app", category: "Spots")

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 候補の検索

    /// 現在地周辺の候補を検索して SwiftData に保存する。同じ場所（5km 以内）で 7 日以内なら再検索しない。
    func searchCandidates(around center: GeoPoint, now: Date = Date()) async {
        if let last = lastSearchCenter, last.distance(to: center) < DesignTokens.Spots.researchDistanceMeters { return }
        if hasRecentCandidates(near: center, now: now) {
            lastSearchCenter = center
            return
        }
        isSearching = true
        defer { isSearching = false }
        var found: [(name: String, point: GeoPoint, source: String)] = []
        for keyword in Self.keywords {
            let results = await Self.localSearch(keyword: keyword, center: center)
            found.append(contentsOf: results.map { ($0.name, $0.point, "mapkit") })
        }
        for port in Tide736.ports where port.point.distance(to: center) <= DesignTokens.Spots.searchRadiusMeters {
            found.append((port.name, port.point, "tide736"))
        }
        var inserted = 0
        for item in found where !exists(name: item.name, near: item.point) {
            context.insert(Spot(name: item.name, latitude: item.point.latitude, longitude: item.point.longitude,
                                isRegistered: false, source: item.source, searchedAt: now))
            inserted += 1
        }
        do {
            try context.save()
        } catch {
            logger.error("候補の保存に失敗: \(error.localizedDescription, privacy: .public)")
        }
        logger.notice("候補検索: \(found.count) 件中 \(inserted) 件を追加")
        lastSearchCenter = center
    }

    private struct SearchHit: Sendable {
        var name: String
        var point: GeoPoint
    }

    private nonisolated static func localSearch(keyword: String, center: GeoPoint) async -> [SearchHit] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.resultTypes = .pointOfInterest
        let span = DesignTokens.Spots.searchSpanDegrees
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.compactMap { item in
                guard let name = item.name, !name.isEmpty else { return nil }
                let coordinate = item.placemark.coordinate
                return SearchHit(name: name, point: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude))
            }
        } catch {
            return []
        }
    }

    private func hasRecentCandidates(near center: GeoPoint, now: Date) -> Bool {
        let since = now.addingTimeInterval(-DesignTokens.Spots.researchInterval)
        let descriptor = FetchDescriptor<Spot>(predicate: #Predicate { $0.isRegistered == false && $0.searchedAt != nil })
        let candidates = (try? context.fetch(descriptor)) ?? []
        return candidates.contains { ($0.searchedAt ?? .distantPast) >= since
            && $0.point.distance(to: center) < DesignTokens.Spots.researchDistanceMeters }
    }

    private func exists(name: String, near point: GeoPoint) -> Bool {
        let descriptor = FetchDescriptor<Spot>(predicate: #Predicate { $0.name == name })
        let same = (try? context.fetch(descriptor)) ?? []
        return same.contains { $0.point.distance(to: point) < 500 }
    }

    // MARK: - 登録

    func register(_ spot: Spot) {
        spot.isRegistered = true
        if spot.source != "seed" { spot.source = "user" }
        do {
            try context.save()
        } catch {
            logger.error("登録に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 現在地を新しい釣り場として登録（名前は逆ジオコーディング、取れなければ「現在地」）。
    func registerCurrentLocation(_ point: GeoPoint) async {
        let name = await Self.placeName(for: point) ?? "現在地"
        let spot = Spot(name: name, latitude: point.latitude, longitude: point.longitude, isRegistered: true, source: "user")
        context.insert(spot)
        do {
            try context.save()
        } catch {
            logger.error("登録に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    private nonisolated static func placeName(for point: GeoPoint) async -> String? {
        let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return nil }
        return placemark.subLocality ?? placemark.locality ?? placemark.name
    }

    // MARK: - 釣れ率

    /// 各釣り場の釣れ率（地点ごとの条件はキャッシュ優先で取得）。
    func refreshScores(spots: [Spot], conditions: ConditionsStore, tide: TideStore, now: Date = Date(),
                       band: TemperatureBand?) async {
        for spot in spots {
            let snapshot = await conditions.snapshot(for: spot.point, at: now)
            let days = await tide.days(for: spot.point, now: now).days
            let day = days.first { now >= $0.dayStart && now < $0.dayStart.addingTimeInterval(86_400) } ?? days.first
            let input = FishingScore.input(at: now, tide: day, weather: snapshot.weather, marine: snapshot.marine, band: band)
            scores[spot.id] = FishingScore.compute(input, weights: ScoreWeightsStore.current).total
            if let direction = snapshot.weather?.windDirection { windDirections[spot.id] = direction }
        }
    }
}
