# STATUS

## 現在地

L4 完了待ち（CI 確認中）→ 次は L5（2026-10-29）

## 次のループ

L5: 釣れ率v1、リング、4条件メーター、24hバー、Detailシート（内訳付き）。

## 既知の問題

- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest、約3分/回）のみ。純粋ロジックは `TideCore` に置き ubuntu の `swift test` でも検証する（ADR-0002）。
- macOS ジョブはコミットメッセージに `[ios]` を含むときだけ走る（ADR-0002）。
- 実機では L16 まで WeatherKit が使えないため、気象は固定値モックに退避する（ADR-0003）。Detail に由来を出す。
- tide736.net は開発コンテナから到達できない。応答形式は GitHub Actions 上のプローブで確認済み（L4）。CI では固定レスポンスでテスト。

## 最後に私がやること

L16 で `docs/OWNER_TASKS.md` に手順をまとめる。それまで手作業は不要。
