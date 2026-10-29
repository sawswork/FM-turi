import SwiftUI
import TideCore

/// A-1 4 日付行: 左=チップ3つ gap6、右=moon20＋潮回り 12/500 補助 gap8。
struct DateChipRow: View {
    let days: [TideDay]
    @Binding var selected: Int
    var timeZone: TimeZone = Tide736.timeZone

    @MainActor private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.timeZone = Tide736.timeZone
        f.dateFormat = "M/d E"
        return f
    }()

    private func label(for day: TideDay) -> String {
        Self.formatter.string(from: day.dayStart)
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: DesignTokens.Chip.gap) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    Button {
                        selected = index
                    } label: {
                        chip(label(for: day), isSelected: index == selected)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            if days.indices.contains(selected) {
                HStack(spacing: DesignTokens.Chip.moonGap) {
                    MoonGlyph(age: days[selected].moonAge)
                    Text(days[selected].tideType.label)
                        .font(DesignTokens.Fonts.text(DesignTokens.Chip.tideTypeFontSize, .w500))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
        }
        .padding(.top, DesignTokens.Chip.rowPadTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
    }

    private func chip(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(DesignTokens.Fonts.text(DesignTokens.Chip.fontSize, .w600))
            .tracking(DesignTokens.Chip.tracking)
            .foregroundStyle(isSelected ? DesignTokens.Colors.black : DesignTokens.Colors.secondary)
            .padding(.horizontal, DesignTokens.Chip.padHorizontal)
            .frame(height: DesignTokens.Chip.height)
            .background(
                isSelected ? DesignTokens.Colors.orange : DesignTokens.Colors.surface,
                in: RoundedRectangle(cornerRadius: DesignTokens.Chip.radius, style: .continuous)
            )
    }
}
