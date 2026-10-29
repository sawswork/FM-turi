import SwiftUI

/// 付録A A-0 のトークン。画面はこの定数だけを使う（直書き禁止: SwiftLint `hex_color_outside_tokens`）。
enum DesignTokens {
    // MARK: - 色

    enum Colors {
        /// 背景 #000000
        static let background = Color(hex: 0x000000)
        /// 面 #1C1C1E
        static let surface = Color(hex: 0x1C1C1E)
        /// 面2 #2C2C2E
        static let surface2 = Color(hex: 0x2C2C2E)
        /// 面3 #111112
        static let surface3 = Color(hex: 0x111112)
        /// シート #121214
        static let sheet = Color(hex: 0x121214)
        /// 非アクティブ #3A3A3C
        static let inactive = Color(hex: 0x3A3A3C)
        /// 補助 #8E8E93
        static let secondary = Color(hex: 0x8E8E93)
        /// 主 #FFFFFF
        static let primary = Color(hex: 0xFFFFFF)
        /// オレンジ #FF9F0A
        static let orange = Color(hex: 0xFF9F0A)
        /// グリーン #30D158
        static let green = Color(hex: 0x30D158)
        /// 地図の陸 #0E0E10（A-4）
        static let land = Color(hex: 0x0E0E10)
        /// 黒（アクティブ要素上の文字・アイコン）
        static let black = Color(hex: 0x000000)
    }

    // MARK: - フォント（SF Pro、数字は等幅）

    enum Fonts {
        static func text(_ size: CGFloat, _ weight: Weight) -> Font {
            Font.system(size: size, weight: weight.fontWeight, design: .default).monospacedDigit()
        }

        enum Weight {
            case w200, w300, w400, w500, w600

            var fontWeight: Font.Weight {
                switch self {
                case .w200: .ultraLight
                case .w300: .light
                case .w400: .regular
                case .w500: .medium
                case .w600: .semibold
                }
            }
        }
    }

    // MARK: - アイコン

    enum Icon {
        static let size: CGFloat = 24
        static let lineWidth: CGFloat = 1.8
    }

    // MARK: - メーター 40×4 r2

    enum Meter {
        static let width: CGFloat = 40
        static let height: CGFloat = 4
        static let radius: CGFloat = 2
    }

    // MARK: - 月相グリフ 20×20

    enum MoonGlyph {
        static let size: CGFloat = 20
        static let radius: CGFloat = 8.5
        static let shadowOpacity: Double = 0.78
    }

    // MARK: - 位置ピル h36 r18

    enum LocationPill {
        static let height: CGFloat = 36
        static let radius: CGFloat = 18
        static let padLeading: CGFloat = 10
        static let padTrailing: CGFloat = 14
        static let gap: CGFloat = 7
        static let pinSize: CGFloat = 15
        static let pinLineWidth: CGFloat = 2
        static let fontSize: CGFloat = 13
    }

    // MARK: - 丸ボタン round36

    enum RoundButton {
        static let size: CGFloat = 36
        static let radius: CGFloat = 18
        static let iconSize: CGFloat = 18
        static let lineWidth: CGFloat = 2
    }

    // MARK: - タブバー

    enum TabBar {
        static let height: CGFloat = 68
        static let radius: CGFloat = 34
        static let marginHorizontal: CGFloat = 20
        static let marginBottom: CGFloat = 22
        static let padHorizontal: CGFloat = 8
        static let itemWidth: CGFloat = 48
        static let itemHeight: CGFloat = 52
        static let iconSize: CGFloat = 24
        static let cameraSize: CGFloat = 54
        /// タブバーが覆う高さ（画面側がコンテンツ下に空ける量）
        static let occupiedHeight: CGFloat = height + marginBottom
    }

    // MARK: - 日付チップ（A-1 4）h30 r15 pad=0 12 12/600 字間0.3

    enum Chip {
        static let height: CGFloat = 30
        static let radius: CGFloat = 15
        static let padHorizontal: CGFloat = 12
        static let fontSize: CGFloat = 12
        static let tracking: CGFloat = 0.3
        static let gap: CGFloat = 6
        static let rowPadTop: CGFloat = 18
        static let moonGap: CGFloat = 8
        static let tideTypeFontSize: CGFloat = 12
    }

    // MARK: - 潮位グラフ（A-1 5）1日 350×150

    enum TideGraph {
        static let dayWidth: CGFloat = 350
        static let height: CGFloat = 150
        static let marginTop: CGFloat = 10
        static let curveTop: CGFloat = 46
        static let curveBottom: CGFloat = 128
        static let fillBottom: CGFloat = 150
        static let curveLineWidth: CGFloat = 2
        static let curveOpacityOther: Double = 0.35
        static let fillOpacity: Double = 0.05
        static let bandWidth: CGFloat = 24
        static let bandHeight: CGFloat = 124
        static let bandY: CGFloat = 4
        static let bandRadius: CGFloat = 12
        static let bandOpacityToday: Double = 0.06
        static let bandOpacityOther: Double = 0.03
        static let bandDefaultX: [CGFloat] = [74, 236]
        static let sunArcStart = CGPoint(x: 30, y: 54)
        static let sunArcControl = CGPoint(x: 175, y: -14)
        static let sunArcEnd = CGPoint(x: 320, y: 54)
        static let sunArcOpacity: Double = 0.18
        static let sunArcLineWidth: CGFloat = 1.5
        static let sunArcDash: [CGFloat] = [1, 5]
        static let tickLabels = ["0", "6", "12", "18"]
        static let tickX: [CGFloat] = [2, 87, 174, 261]
        static let tickY: CGFloat = 146
        static let tickFontSize: CGFloat = 10
        static let boundaryTop: CGFloat = 8
        static let boundaryBottom: CGFloat = 128
        static let boundaryOpacity: Double = 0.12
        static let sunPointRadius: CGFloat = 5
        static let sunHaloRadius: CGFloat = 10
        static let sunHaloOpacity: Double = 0.12
        static let nowLineTop: CGFloat = 30
        static let nowLineBottom: CGFloat = 128
        static let nowLineOpacity: Double = 0.35
        static let nowLineDash: [CGFloat] = [2, 4]
        static let nowPointRadius: CGFloat = 6
        static let nowHaloRadius: CGFloat = 14
        static let nowHaloOpacity: Double = 0.18
        static let nowLabelOffset = CGPoint(x: 11, y: 40)
        static let nowLabelFontSize: CGFloat = 11
    }

    // MARK: - 画面共通

    enum Screen {
        /// 上部帯 h72 pad=26 24 0 24
        static let topBarHeight: CGFloat = 72
        static let topBarPadTop: CGFloat = 26
        static let horizontalPadding: CGFloat = 24
        static let width: CGFloat = 390
        static let height: CGFloat = 844
    }
}

extension Color {
    /// 0xRRGGBB の16進から sRGB 色を作る。DesignTokens.swift 以外で使わない。
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
