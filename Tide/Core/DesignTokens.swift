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

    // MARK: - Home リング領域（A-1 2）h268、リング240 r102

    enum HomeRing {
        static let areaHeight: CGFloat = 268
        static let size: CGFloat = 240
        static let radius: CGFloat = 102
        static let lineWidth: CGFloat = 13
        static let haloLineWidth: CGFloat = 28
        static let haloOpacity: Double = 0.10
        static let numberFontSize: CGFloat = 86
        static let numberTracking: CGFloat = -4
        static let dotsTop: CGFloat = 8
        static let dotSize: CGFloat = 5
        static let dotGap: CGFloat = 5
        static let dotCount = 5
        /// 数字の中心から点の中心までの縦オフセット
        static let dotsOffsetY: CGFloat = 44
    }

    // MARK: - 4条件（A-1 3）4列 gap10 pad=0 36、各h60 gap12

    enum Conditions {
        static let columns = 4
        static let gap: CGFloat = 10
        static let padHorizontal: CGFloat = 36
        static let cellHeight: CGFloat = 60
        static let iconMeterGap: CGFloat = 12
        static let iconSize: CGFloat = 24
    }

    // MARK: - 24時間バー（A-1 6）pad=10 24 0 24 h50 gap5 r3

    enum HourBar {
        static let padTop: CGFloat = 10
        static let height: CGFloat = 50
        static let gap: CGFloat = 5
        static let radius: CGFloat = 3
        static let baseHeight: CGFloat = 6
        static let scale: CGFloat = 0.42
        static let highlightThreshold = 60
    }

    // MARK: - Detail（A-3）

    enum Detail {
        static let topHeight: CGFloat = 150
        static let topOpacity: Double = 0.3
        static let ringSize: CGFloat = 120
        static let ringRadius: CGFloat = 50
        static let ringLineWidth: CGFloat = 9
        static let sheetHeight: CGFloat = 694
        static let sheetRadius: CGFloat = 32
        static let sheetPadTop: CGFloat = 12
        static let handleWidth: CGFloat = 36
        static let handleHeight: CGFloat = 5
        static let handleRadius: CGFloat = 3
        static let handleBottom: CGFloat = 14
        static let placeRowBottom: CGFloat = 8
        static let placePinSize: CGFloat = 13
        static let placeFontSize: CGFloat = 13
        static let gridColumnGap: CGFloat = 24
        static let cellHeight: CGFloat = 70
        static let cellPadTop: CGFloat = 12
        static let cellPadBottom: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let labelFontSize: CGFloat = 11
        static let labelTracking: CGFloat = 0.8
        static let valueFontSize: CGFloat = 26
        static let valueTracking: CGFloat = -1
        static let unitFontSize: CGFloat = 12
        static let unitGap: CGFloat = 4
        static let moonRowPadTop: CGFloat = 12
        static let moonRowPadBottom: CGFloat = 10
        static let moonGlyphSize: CGFloat = 18
        static let moonGlyphRadius: CGFloat = 7.65
        static let moonGap: CGFloat = 14
        static let moonCount = 7
        static let moonTodayBorder: CGFloat = 1.5
        static let moonOtherOpacity: Double = 0.45
        static let breakdownPadTop: CGFloat = 14
        static let breakdownGap: CGFloat = 10
        static let breakdownLabelWidth: CGFloat = 46
        static let breakdownBarHeight: CGFloat = 6
        static let breakdownBarRadius: CGFloat = 3
        static let breakdownValueWidth: CGFloat = 30
        static let breakdownValueFontSize: CGFloat = 12
        static let breakdownOrangeThreshold: Double = 0.5
        static let closeHeight: CGFloat = 56
        static let closeIconSize: CGFloat = 22
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

    // MARK: - Catch（A-2）

    enum Catch {
        static let photoHeight: CGFloat = 480
        static let photoBottomRadius: CGFloat = 36
        static let guideLineWidth: CGFloat = 1.5
        static let guideOpacity: Double = 0.22
        static let guideFillOpacity: Double = 0.04
        static let guideSize = CGSize(width: 200, height: 96)
        static let bracketRadius: CGFloat = 14
        static let bracketLineWidth: CGFloat = 2
        static let bracketLength: CGFloat = 28
        static let bracketTopLeft = CGPoint(x: 48, y: 96)
        static let bracketTopRight = CGPoint(x: 310, y: 64)
        static let bracketBottomLeft = CGPoint(x: 48, y: 400)
        static let bracketBottomRight = CGPoint(x: 352, y: 400)
        static let dottedY: CGFloat = 260
        static let dottedX0: CGFloat = 62
        static let dottedX1: CGFloat = 328
        static let dottedOpacity: Double = 0.35
        static let dottedDash: [CGFloat] = [2, 6]
        static let closeTop: CGFloat = 26
        static let closeLeft: CGFloat = 24
        static let closeSize: CGFloat = 36
        static let closeIconSize: CGFloat = 16
        static let chipTop: CGFloat = 30
        static let chipRight: CGFloat = 24
        static let chipHeight: CGFloat = 28
        static let chipRadius: CGFloat = 14
        static let chipPadLeading: CGFloat = 10
        static let chipPadTrailing: CGFloat = 12
        static let chipGap: CGFloat = 6
        static let chipPinSize: CGFloat = 12
        static let chipPinLineWidth: CGFloat = 2.2
        static let chipFontSize: CGFloat = 11
        static let sizePillLeft: CGFloat = 24
        static let sizePillBottom: CGFloat = 22
        static let sizePillHeight: CGFloat = 44
        static let sizePillRadius: CGFloat = 22
        static let sizePillPadLeading: CGFloat = 14
        static let sizePillPadTrailing: CGFloat = 18
        static let sizePillGap: CGFloat = 10
        static let sizePillIconSize: CGFloat = 18
        static let sizePillFontSize: CGFloat = 22
        static let sizePillFieldWidth: CGFloat = 44
        static let aiRingRight: CGFloat = 24
        static let aiRingBottom: CGFloat = 22
        static let aiRingSize: CGFloat = 44
        static let aiRingInner: CGFloat = 30
        static let aiRingRadius: CGFloat = 12
        static let aiRingLineWidth: CGFloat = 2.5
        static let aiRingDotRadius: CGFloat = 2.5
        static let candidateColumns = 3
        static let candidateGap: CGFloat = 10
        static let candidatePadTop: CGFloat = 18
        static let candidateHeight: CGFloat = 64
        static let candidateRadius: CGFloat = 20
        static let candidateFishSize = CGSize(width: 56, height: 30)
        static let candidateLineWidth: CGFloat = 1.8
        static let autoPadTop: CGFloat = 18
        static let autoPadHorizontal: CGFloat = 36
        static let autoGap: CGFloat = 10
        static let autoVerticalGap: CGFloat = 8
        static let autoIconSize: CGFloat = 20
        static let autoFontSize: CGFloat = 16
        static let miniCurveSize = CGSize(width: 26, height: 16)
        static let tacklePadTop: CGFloat = 18
        static let tackleGap: CGFloat = 8
        static let tackleHeight: CGFloat = 34
        static let tackleRadius: CGFloat = 17
        static let tacklePadHorizontal: CGFloat = 14
        static let tackleInnerGap: CGFloat = 6
        static let tackleIconSize: CGFloat = 14
        static let tackleFontSize: CGFloat = 13
        static let saveHeight: CGFloat = 60
        static let saveRadius: CGFloat = 30
        static let saveIconSize: CGFloat = 26
        static let saveIconLineWidth: CGFloat = 2.2
        static let savePadBottom: CGFloat = 24
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
