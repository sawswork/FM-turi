import CoreLocation
import Foundation
import Observation
import OSLog
import TideCore

/// 現在地。CLLocationUpdate.liveUpdates で最初の測位を取り、以後は数分ごとに更新する。
/// 測位できない間は既定点（城ヶ島）を使う。
@MainActor
@Observable
final class LocationService {
    /// 付録A の例と同じ場所（城ヶ島）。測位前・シミュレータでの既定値。
    static let fallbackPoint = GeoPoint(latitude: 35.1352, longitude: 139.6079)

    private(set) var current: GeoPoint = LocationService.fallbackPoint
    private(set) var hasFix = false
    private(set) var isDenied = false

    private let logger = Logger(subsystem: "jp.tide.app", category: "Location")
    private var task: Task<Void, Never>?

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let self else { return }
                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        isDenied = true
                        logger.notice("位置情報が拒否されたため既定点を使用")
                        return
                    }
                    if let location = update.location {
                        current = GeoPoint(latitude: location.coordinate.latitude,
                                           longitude: location.coordinate.longitude)
                        hasFix = true
                        // 1回取れたら止める（省電力）。再開は start() の呼び直し。
                        return
                    }
                }
            } catch {
                self?.logger.error("測位エラー: \(error.localizedDescription, privacy: .public)")
            }
            self?.task = nil
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
