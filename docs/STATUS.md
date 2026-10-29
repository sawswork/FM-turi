# STATUS

## 現在地

L14 実装済み（CI 停止中のため未検証）→ 次は L15（2026-10-29）

## 次のループ

L15: 釣れ率v2、気象警報表示、設定画面（注意書き・データ削除）。

## 既知の問題

- **【要対応・オーナー】GitHub Actions が止まっている（2026-10-29 17:11 UTC〜）。** 全ジョブが「The job was not started because recent account payments have failed or your spending limit needs to be increased」で即失敗する。GitHub の Settings → Billing & plans で支払い方法か Actions の spending limit を確認すると直る。直るまで CI での検証（SwiftLint 全ルール・TideCore テスト・iOS ビルド）ができないため、以降のループは「CI 未検証」として進め、復旧後に最新コミットへ手動で CI を回して赤を直す。

- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest、約3分/回）のみ。純粋ロジックは `TideCore` に置き ubuntu の `swift test` でも検証する（ADR-0002）。
- macOS ジョブはコミットメッセージに `[ios]` を含むときだけ走る（ADR-0002）。
- 実機では L16 まで WeatherKit が使えないため、気象は固定値モックに退避する（ADR-0003）。Detail に由来を出す。
- tide736.net は開発コンテナから到達できない。応答形式は GitHub Actions 上のプローブで確認済み（L4）。CI では固定レスポンスでテスト。

## 最後に私がやること

L16 で `docs/OWNER_TASKS.md` に手順をまとめる。それまで手作業は不要。
