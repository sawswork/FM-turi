import SwiftUI

/// 注意書き（指示書 §3-1・§4）。初回起動と設定画面で表示する。
struct NoticeView: View {
    /// 確認ボタンを出す（初回起動）。設定画面では出さない
    var showsConfirm = true
    var onConfirm: () -> Void = {}

    static let acceptedKey = "notice.accepted.v1"

    static let title = "ご利用の前に"
    static let paragraphs = [
        "このアプリの潮汐・日出没・気象・海況の情報は参考値です。航海の用に使用しないでください。",
        "釣り場の候補は地図検索の結果であり、釣りの可否（釣り禁止・立入禁止など）は判定していません。必ず現地の表示に従ってください。",
        "気象警報・注意報が出ているときは、海や堤防に近づかないでください。",
        "記録・写真・設定はこの端末の中にだけ保存されます。"
    ]

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: DesignTokens.Notice.gap) {
                Text(Self.title)
                    .font(DesignTokens.Fonts.text(DesignTokens.Notice.titleFontSize, .w600))
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .padding(.top, DesignTokens.Notice.padTop)
                ForEach(Array(Self.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(DesignTokens.Fonts.text(DesignTokens.Notice.bodyFontSize, .w400))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .lineSpacing(DesignTokens.Notice.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if showsConfirm {
                    Button(action: onConfirm) {
                        RoundedRectangle(cornerRadius: DesignTokens.Notice.buttonRadius, style: .continuous)
                            .fill(DesignTokens.Colors.orange)
                            .frame(height: DesignTokens.Notice.buttonHeight)
                            .overlay {
                                IconView(icon: .check, size: DesignTokens.Notice.buttonIconSize,
                                         lineWidth: DesignTokens.Notice.buttonIconLineWidth, color: DesignTokens.Colors.black)
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, DesignTokens.Notice.padBottom)
                }
            }
            .padding(.horizontal, DesignTokens.Screen.horizontalPadding)
        }
    }
}

#Preview {
    NoticeView()
}
