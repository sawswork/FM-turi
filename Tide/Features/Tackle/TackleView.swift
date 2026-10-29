import SwiftData
import SwiftUI
import TideCore

/// 付録A A-6 Tackle。シンカー（円＋在庫）、フック（ステッパー）、行列（L14）。
struct TackleView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Query(sort: \TackleItem.sortOrder) private var tackle: [TackleItem]
    @Query private var records: [CatchRecord]

    private typealias Tkl = DesignTokens.Tackle

    private var sinkers: [TackleItem] { tackle.filter { $0.kind == .sinker } }
    private var hooks: [TackleItem] { tackle.filter { $0.kind == .hook } }

    /// 使用頻度（釣果の記録から数える。L14）
    private var usage: TackleUsage { TackleUsage(records: records, sinkers: sinkers, hooks: hooks) }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                TopBarView {
                    RoundButton(icon: .chevronLeft) { router.selectedTab = .home }
                } trailing: {
                    RoundButton(icon: .plus) { addOneToSelected() }
                }
                ScrollView {
                    VStack(spacing: 0) {
                        heading(icon: .sinker, text: "g")
                            .padding(.top, Tkl.headingPadTop)
                        sinkerCircles
                        stockRow
                        heading(icon: .hook, text: "#")
                            .padding(.top, Tkl.hookHeadingPadTop)
                        hookGrid
                        TackleMatrixView(tackle: tackle, values: usage.matrix)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func heading(icon: TideIcon, text: String) -> some View {
        HStack(spacing: Tkl.headingGap) {
            IconView(icon: icon, size: Tkl.headingIconSize, color: DesignTokens.Colors.secondary)
            Text(text)
                .font(DesignTokens.Fonts.text(Tkl.headingFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
    }

    // MARK: - シンカー

    private var sinkerCircles: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(sinkers.enumerated()), id: \.element.key) { index, item in
                let diameter = Tkl.circleDiameters[min(index, Tkl.circleDiameters.count - 1)]
                let fontSize = Tkl.circleFontSizes[min(index, Tkl.circleFontSizes.count - 1)]
                Button {
                    select(item)
                } label: {
                    Circle()
                        .fill(item.isSelected ? DesignTokens.Colors.orange : DesignTokens.Colors.surface)
                        .frame(width: diameter, height: diameter)
                        .overlay {
                            Text(item.label)
                                .font(DesignTokens.Fonts.text(fontSize, .w400))
                                .foregroundStyle(item.isSelected ? DesignTokens.Colors.black : DesignTokens.Colors.primary)
                        }
                }
                .buttonStyle(.plain)
                if index < sinkers.count - 1 { Spacer(minLength: 0) }
            }
        }
        .frame(height: Tkl.circlesRowHeight, alignment: .bottom)
        .padding(.top, Tkl.circlesPadTop)
        .padding(.horizontal, Tkl.circlesPadHorizontal)
    }

    private var stockRow: some View {
        let usage = usage
        return HStack(spacing: 0) {
            ForEach(Array(sinkers.enumerated()), id: \.element.key) { index, item in
                VStack(spacing: Tkl.stockGap) {
                    Text("\(item.stock)")
                        .font(DesignTokens.Fonts.text(Tkl.stockFontSize, .w500))
                        .foregroundStyle(DesignTokens.Colors.primary)
                    MeterView(fraction: usage.sinkerShare(item.label),
                              width: Tkl.stockMeterWidth, height: Tkl.stockMeterHeight)
                }
                .frame(width: Tkl.stockColumnWidth)
                .contentShape(Rectangle())
                .onTapGesture { adjust(item, by: 1) }
                .onLongPressGesture { adjust(item, by: -1) }
                if index < sinkers.count - 1 { Spacer(minLength: 0) }
            }
        }
        .padding(.top, Tkl.stockRowPadTop)
        .padding(.horizontal, Tkl.stockRowPadHorizontal)
    }

    // MARK: - フック

    private var hookGrid: some View {
        HStack(alignment: .top, spacing: Tkl.hookGridGap) {
            ForEach(Array(hooks.enumerated()), id: \.element.key) { index, item in
                VStack(spacing: Tkl.hookColumnGap) {
                    Button {
                        select(item)
                    } label: {
                        IconView(icon: .hook, size: Tkl.hookIconSizes[min(index, Tkl.hookIconSizes.count - 1)],
                                 color: item.isSelected ? DesignTokens.Colors.orange : DesignTokens.Colors.primary)
                            .frame(height: Tkl.hookIconSizes.last ?? 32)
                    }
                    .buttonStyle(.plain)
                    Text(item.label)
                        .font(DesignTokens.Fonts.text(Tkl.hookLabelFontSize, .w600))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    stepper(item)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, Tkl.hookGridPadTop)
        .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
    }

    private func stepper(_ item: TackleItem) -> some View {
        HStack(spacing: 0) {
            Button { adjust(item, by: -1) } label: {
                Text("−")
                    .font(DesignTokens.Fonts.text(Tkl.stepperSignFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .frame(width: Tkl.stepperButtonWidth, height: Tkl.stepperHeight)
            }
            .buttonStyle(.plain)
            Text("\(item.stock)")
                .font(DesignTokens.Fonts.text(Tkl.stepperValueFontSize, .w600))
                .foregroundStyle(DesignTokens.Colors.primary)
                .frame(minWidth: Tkl.stepperValueMinWidth)
                .frame(maxWidth: .infinity)
            Button { adjust(item, by: 1) } label: {
                Text("+")
                    .font(DesignTokens.Fonts.text(Tkl.stepperSignFontSize, .w500))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .frame(width: Tkl.stepperButtonWidth, height: Tkl.stepperHeight)
            }
            .buttonStyle(.plain)
        }
        .frame(height: Tkl.stepperHeight)
        .background(DesignTokens.Colors.surface, in: RoundedRectangle(cornerRadius: Tkl.stepperRadius, style: .continuous))
    }

    // MARK: - 操作

    private func adjust(_ item: TackleItem, by delta: Int) {
        item.stock = max(0, item.stock + delta)
        save()
    }

    private func select(_ item: TackleItem) {
        for other in tackle where other.kind == item.kind {
            other.isSelected = other.key == item.key
        }
        save()
    }

    private func addOneToSelected() {
        for item in tackle where item.isSelected {
            item.stock += 1
        }
        save()
    }

    private func save() {
        try? context.save()
        StockSync.publish(context: context)
    }
}

/// 使用頻度の集計（釣果の記録ベース）。
struct TackleUsage {
    let sinkerCounts: [String: Int]
    let hookCounts: [String: Int]
    /// 行=フック、列=シンカー の使用回数
    let matrix: [[Int]]

    init(records: [CatchRecord], sinkers: [TackleItem], hooks: [TackleItem]) {
        var sinkerCounts: [String: Int] = [:]
        var hookCounts: [String: Int] = [:]
        var matrix = Array(repeating: Array(repeating: 0, count: sinkers.count), count: hooks.count)
        for record in records {
            let sinkerLabel = record.sinkerGrams.map(String.init)
            if let sinkerLabel { sinkerCounts[sinkerLabel, default: 0] += 1 }
            if let hook = record.hookSize { hookCounts[hook, default: 0] += 1 }
            if let sinkerLabel, let hook = record.hookSize,
               let row = hooks.firstIndex(where: { $0.label == hook }),
               let column = sinkers.firstIndex(where: { $0.label == sinkerLabel }) {
                matrix[row][column] += 1
            }
        }
        self.sinkerCounts = sinkerCounts
        self.hookCounts = hookCounts
        self.matrix = matrix
    }

    /// そのシンカーの使用回数 ÷ 最多の使用回数（0...1）。
    func sinkerShare(_ label: String) -> Double {
        let maxCount = max(sinkerCounts.values.max() ?? 0, 1)
        return Double(sinkerCounts[label] ?? 0) / Double(maxCount)
    }
}

/// A-6 4 行列: 1行目=シンカー、左列=フック、セルの円 直径 6+値×3（≥5 橙、≥3 白、他 面2）。
struct TackleMatrixView: View {
    let tackle: [TackleItem]
    var values: [[Int]] = []

    private typealias Tkl = DesignTokens.Tackle

    private var sinkers: [TackleItem] { tackle.filter { $0.kind == .sinker } }
    private var hooks: [TackleItem] { tackle.filter { $0.kind == .hook } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Tkl.headingGap) {
                FishSilhouette(kind: .rock)
                    .stroke(DesignTokens.Colors.secondary, style: StrokeStyle(lineWidth: Tkl.matrixFishLineWidth, lineJoin: .round))
                    .frame(width: Tkl.matrixFishSize.width, height: Tkl.matrixFishSize.height)
                Text("×")
                    .font(DesignTokens.Fonts.text(Tkl.headingFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Spacer(minLength: 0)
            }
            .padding(.top, Tkl.matrixHeadingPadTop)
            .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
            Grid(horizontalSpacing: Tkl.matrixGap, verticalSpacing: Tkl.matrixGap) {
                GridRow {
                    Color.clear.frame(width: Tkl.matrixLabelColumnWidth, height: Tkl.matrixRowHeight)
                    ForEach(sinkers, id: \.key) { sinker in
                        Text(sinker.label)
                            .font(DesignTokens.Fonts.text(Tkl.matrixHeaderFontSize, .w600))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: Tkl.matrixRowHeight)
                    }
                }
                ForEach(Array(hooks.enumerated()), id: \.element.key) { row, hook in
                    GridRow {
                        Text(hook.label)
                            .font(DesignTokens.Fonts.text(Tkl.matrixHeaderFontSize, .w600))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .frame(width: Tkl.matrixLabelColumnWidth, height: Tkl.matrixRowHeight, alignment: .leading)
                        ForEach(Array(sinkers.enumerated()), id: \.element.key) { column, _ in
                            let value = values.indices.contains(row) && values[row].indices.contains(column) ? values[row][column] : 0
                            Circle()
                                .fill(value >= Tkl.matrixOrangeThreshold ? DesignTokens.Colors.orange
                                      : (value >= Tkl.matrixWhiteThreshold ? DesignTokens.Colors.primary : DesignTokens.Colors.surface2))
                                .frame(width: Tkl.matrixDotBase + CGFloat(value) * Tkl.matrixDotScale,
                                       height: Tkl.matrixDotBase + CGFloat(value) * Tkl.matrixDotScale)
                                .frame(maxWidth: .infinity)
                                .frame(height: Tkl.matrixRowHeight)
                        }
                    }
                }
            }
            .padding(.top, Tkl.matrixGridPadTop)
            .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        }
    }
}

#Preview {
    TackleView()
        .previewEnvironment()
}
