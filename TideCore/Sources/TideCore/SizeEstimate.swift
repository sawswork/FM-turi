import Foundation

/// 基準物（メジャー・500円硬貨）から魚の体長を換算する（指示書 §4）。
public enum SizeEstimate {
    /// 500円硬貨の直径 mm
    public static let coinDiameterMm = 26.5

    public struct Reference: Hashable, Sendable {
        public enum Kind: String, Sendable { case coin, ruler, lidar }
        public var kind: Kind
        /// 基準物の画像上の長さ（px）
        public var pixelLength: Double
        /// 基準物の実寸 mm
        public var realLengthMm: Double

        public init(kind: Kind, pixelLength: Double, realLengthMm: Double) {
            self.kind = kind
            self.pixelLength = pixelLength
            self.realLengthMm = realLengthMm
        }

        /// 1px あたりの mm
        public var mmPerPixel: Double? {
            guard pixelLength > 0, realLengthMm > 0 else { return nil }
            return realLengthMm / pixelLength
        }
    }

    /// 魚の画像上の長さ（px）→ cm。推定できなければ nil（ユーザー入力に任せる）。
    public static func lengthCm(fishPixelLength: Double, reference: Reference) -> Double? {
        guard fishPixelLength > 0, let mmPerPixel = reference.mmPerPixel else { return nil }
        let cm = fishPixelLength * mmPerPixel / 10
        guard cm >= 3, cm <= 200 else { return nil }
        return (cm * 10).rounded() / 10
    }

    /// 硬貨の検出枠（正規化 0...1 の幅・高さと画像の画素数）から基準を作る。枠はほぼ正方形のはず。
    public static func coinReference(boxWidth: Double, boxHeight: Double,
                                     imageWidth: Double, imageHeight: Double) -> Reference? {
        let w = boxWidth * imageWidth
        let h = boxHeight * imageHeight
        guard w > 0, h > 0 else { return nil }
        let ratio = max(w, h) / min(w, h)
        guard ratio < 1.35 else { return nil }
        return Reference(kind: .coin, pixelLength: (w + h) / 2, realLengthMm: coinDiameterMm)
    }

    /// LiDAR: 距離 d(m) とカメラの画角から 1px あたりの実寸。fx = 焦点距離(px)。
    public static func lidarReference(distanceMeters: Double, focalLengthPx: Double) -> Reference? {
        guard distanceMeters > 0, focalLengthPx > 0 else { return nil }
        // 1px の実長 = d / fx （m）→ mm
        let mmPerPixel = distanceMeters / focalLengthPx * 1000
        return Reference(kind: .lidar, pixelLength: 1, realLengthMm: mmPerPixel)
    }
}
