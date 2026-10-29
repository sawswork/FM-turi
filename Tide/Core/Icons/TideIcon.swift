import SwiftUI

/// 付録A A-0 のアイコン集合。SF Symbols を第一候補、該当がないものは Path で描く。
enum TideIcon: Sendable {
    case home, pin, dots, wind, wave, drop, pressure
    case camera, book, hook, sinker, ruler, fish
    case check, plus, close, chevronLeft, chevronDown

    /// SF Symbols で代替するものの名前。Path で描くものは nil。
    var systemName: String? {
        switch self {
        case .home: "circle.circle"
        case .pin: "mappin"
        case .dots: "ellipsis"
        case .wind: "arrow.up"
        case .drop: "drop"
        case .camera: "camera"
        case .book: "book"
        case .ruler: "ruler"
        case .check: "checkmark"
        case .plus: "plus"
        case .close: "xmark"
        case .chevronLeft: "chevron.left"
        case .chevronDown: "chevron.down"
        case .wave, .pressure, .hook, .sinker, .fish: nil
        }
    }

    /// wind は上向き矢印を時計回り40°回転。
    var rotation: Angle {
        switch self {
        case .wind: .degrees(40)
        default: .zero
        }
    }
}

/// アイコンを size×size のアウトラインで描く。
struct IconView: View {
    let icon: TideIcon
    var size: CGFloat = DesignTokens.Icon.size
    var lineWidth: CGFloat = DesignTokens.Icon.lineWidth
    var color: Color = DesignTokens.Colors.primary

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    }

    var body: some View {
        Group {
            if let name = icon.systemName {
                Image(systemName: name)
                    .font(.system(size: size * 0.78, weight: symbolWeight))
                    .rotationEffect(icon.rotation)
            } else {
                pathIcon
            }
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
    }

    private var symbolWeight: Font.Weight {
        lineWidth >= 2.2 ? .medium : (lineWidth >= 1.9 ? .regular : .light)
    }

    @ViewBuilder
    private var pathIcon: some View {
        switch icon {
        case .hook: HookShape().stroke(color, style: strokeStyle)
        case .sinker: SinkerShape().stroke(color, style: strokeStyle)
        case .fish: FishShape().stroke(color, style: strokeStyle)
        case .wave: WaveShape().stroke(color, style: strokeStyle)
        case .pressure: PressureShape().stroke(color, style: strokeStyle)
        default: EmptyView()
        }
    }
}

#Preview("Icons") {
    let icons: [TideIcon] = [
        .home, .pin, .dots, .wind, .wave, .drop, .pressure, .camera, .book,
        .hook, .sinker, .ruler, .fish, .check, .plus, .close, .chevronLeft, .chevronDown
    ]
    return LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 6)) {
        ForEach(Array(icons.enumerated()), id: \.offset) { _, icon in
            IconView(icon: icon)
        }
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
