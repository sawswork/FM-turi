import Foundation
import SwiftData
import TideCore

/// 釣果1件。写真はアプリ内に縮小保存（長辺1024）、その時刻の条件を一緒に持つ。
@Model
final class CatchRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    /// 写真の撮影時刻（EXIF）か保存時刻
    var capturedAt: Date
    /// 付録B の id（"other" を含む）
    var speciesID: String
    /// Vision の候補（id）と確度（L7）
    var candidateIDs: [String]
    var candidateConfidences: [Double]
    /// 確定した候補の確度（0...1、無ければ nil）
    var confidence: Double?
    var lengthCm: Double?
    /// サイズの出どころ: "coin" / "ruler" / "lidar" / nil=ユーザー入力
    var lengthSource: String?
    var spotName: String
    var latitude: Double?
    var longitude: Double?
    /// PhotoStore 内のファイル名
    var photoFileName: String?
    var photoWidth: Double
    var photoHeight: Double

    // その時刻の条件
    var scoreTotal: Int
    /// 保存時の v1 要素点数（FishingScore.Key.allCases の順。釣れ率 v2 の学習に使う）
    var componentPoints: [Int]
    var tideLevelCm: Double?
    var tideRising: Bool?
    var tideType: String?
    var moonAge: Double?
    var windSpeed: Double?
    var windDirection: Double?
    var pressure: Double?
    var pressureTrend3h: Double?
    var airTemperature: Double?
    var seaSurfaceTemperature: Double?
    var waveHeight: Double?

    // タックル（L8 で紐付け）
    var sinkerGrams: Int?
    var hookSize: String?

    init(id: UUID = UUID(), createdAt: Date = Date(), capturedAt: Date, speciesID: String,
         candidateIDs: [String] = [], candidateConfidences: [Double] = [], confidence: Double? = nil,
         lengthCm: Double? = nil, spotName: String, latitude: Double? = nil, longitude: Double? = nil,
         photoFileName: String? = nil, photoWidth: Double = 0, photoHeight: Double = 0,
         scoreTotal: Int = 0, componentPoints: [Int] = [], sinkerGrams: Int? = nil, hookSize: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.capturedAt = capturedAt
        self.speciesID = speciesID
        self.candidateIDs = candidateIDs
        self.candidateConfidences = candidateConfidences
        self.confidence = confidence
        self.lengthCm = lengthCm
        self.spotName = spotName
        self.latitude = latitude
        self.longitude = longitude
        self.photoFileName = photoFileName
        self.photoWidth = photoWidth
        self.photoHeight = photoHeight
        self.scoreTotal = scoreTotal
        self.componentPoints = componentPoints
        self.sinkerGrams = sinkerGrams
        self.hookSize = hookSize
    }

    var species: Species? { Species.find(speciesID) }

    /// 条件を一括で書き込む。
    func apply(tide: TideDay?, at date: Date, weather: WeatherSnapshot?, marine: MarineSnapshot?) {
        tideLevelCm = tide?.level(at: date)
        tideRising = tide?.isRising(at: date)
        tideType = tide?.tideType.rawValue
        moonAge = tide?.moonAge
        windSpeed = weather?.windSpeed
        windDirection = weather?.windDirection
        pressure = weather?.pressure
        pressureTrend3h = weather?.pressureTrend3h
        airTemperature = weather?.airTemperature
        seaSurfaceTemperature = marine?.seaSurfaceTemperature
        waveHeight = marine?.waveHeight
    }
}
