import SwiftData
import SwiftUI
import TideCore

/// 設定（L15）: 注意書き、釣れ率 v2 の状態、学習用の書き出し、データ削除。Home の … から開く。
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [CatchRecord]
    @State private var exportURL: URL?
    @State private var confirmDelete = false
    @State private var isWorking = false

    private typealias Stg = DesignTokens.Settings

    private var weights: FishingScore.Weights { ScoreWeightsStore.current }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Stg.sectionGap) {
                    HStack {
                        Spacer(minLength: 0)
                        RoundButton(icon: .close) { dismiss() }
                    }
                    .padding(.top, Stg.padTop)

                    section("釣れ率") {
                        row(label: weights.isV1 ? "v1（指示書の配点）" : "v2（釣果 \(weights.sampleCount) 件から学習）",
                            detail: weights.learnedAt.map { TimeFormat.monthDayWeekdayTime.string(from: $0) } ?? "")
                        ForEach(FishingScore.Key.allCases, id: \.self) { key in
                            row(label: key.rawValue, detail: String(format: "%.0f", weights.weight(key)))
                        }
                        button("釣果から学び直す（\(records.count) 件）") {
                            isWorking = true
                            Task {
                                await ScoreV2Trainer.retrain(context: context)
                                isWorking = false
                            }
                        }
                    }

                    section("学習データ") {
                        button("学習用に書き出す（写真を魚種ごとに ZIP）") {
                            exportURL = DataExport.makeTrainingZip(context: context)
                        }
                        if let exportURL {
                            ShareLink(item: exportURL) {
                                buttonLabel("ZIP を共有・保存")
                            }
                        }
                    }

                    section("データ") {
                        button("すべての記録・写真・キャッシュを削除", destructive: true) { confirmDelete = true }
                    }

                    section(NoticeView.title) {
                        ForEach(Array(NoticeView.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(DesignTokens.Fonts.text(Stg.bodyFontSize, .w400))
                                .foregroundStyle(DesignTokens.Colors.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    row(label: "Tide", detail: Self.versionText)
                        .padding(.bottom, Stg.padBottom)
                }
                .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
            }
            .scrollIndicators(.hidden)
        }
        .confirmationDialog("すべての記録・写真・キャッシュを削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("削除", role: .destructive) { DataExport.deleteAll(context: context) }
            Button("キャンセル", role: .cancel) {}
        }
        .disabled(isWorking)
    }

    static var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Stg.rowGap) {
            Text(title)
                .font(DesignTokens.Fonts.text(DesignTokens.Detail.labelFontSize, .w600))
                .tracking(DesignTokens.Detail.labelTracking)
                .foregroundStyle(DesignTokens.Colors.secondary)
            content()
        }
        .padding(.top, Stg.sectionPadTop)
        .overlay(alignment: .top) { Rectangle().fill(DesignTokens.Colors.surface2).frame(height: 1) }
    }

    private func row(label: String, detail: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Fonts.text(Stg.bodyFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.primary)
            Spacer(minLength: 0)
            Text(detail)
                .font(DesignTokens.Fonts.text(Stg.bodyFontSize, .w500))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
        .frame(minHeight: Stg.rowHeight)
    }

    private func button(_ title: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            buttonLabel(title, destructive: destructive)
        }
        .buttonStyle(.plain)
    }

    private func buttonLabel(_ title: String, destructive: Bool = false) -> some View {
        Text(title)
            .font(DesignTokens.Fonts.text(Stg.bodyFontSize, .w600))
            .foregroundStyle(destructive ? DesignTokens.Colors.orange : DesignTokens.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: Stg.buttonHeight)
            .background(DesignTokens.Colors.surface, in: RoundedRectangle(cornerRadius: Stg.buttonRadius, style: .continuous))
    }
}

#Preview {
    SettingsView()
        .previewEnvironment()
}
