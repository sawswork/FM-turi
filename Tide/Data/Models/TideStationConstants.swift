import Foundation
import SwiftData
import TideCore

/// 港ごとの調和定数（tide736 の予測値から当てはめ）。あれば潮汐は端末内で計算する。
@Model
final class TideStationConstants {
    @Attribute(.unique) var stationCode: String
    var fittedAt: Date
    var sampleCount: Int
    var rmsErrorCm: Double
    var payload: Data

    init(stationCode: String, constants: HarmonicTide.Constants) {
        self.stationCode = stationCode
        self.fittedAt = constants.fittedAt
        self.sampleCount = constants.sampleCount
        self.rmsErrorCm = constants.rmsErrorCm
        self.payload = (try? JSONEncoder().encode(constants)) ?? Data()
    }

    var constants: HarmonicTide.Constants? {
        try? JSONDecoder().decode(HarmonicTide.Constants.self, from: payload)
    }

    /// 当てはめに使う日数と、許容する残差（cm）。
    static let fitDays = 30
    static let maxRmsErrorCm = 6.0
}
