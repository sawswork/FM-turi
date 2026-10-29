# STATUS

## 現在地

L3 完了待ち（CI 確認中）→ 次は L4（2026-10-29）

## 次のループ

L4: tide736、日出没、月齢、潮回り、Homeの3日横スクロール潮位グラフ。

## 既知の問題

- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest、約3分/回）のみ。純粋ロジックは `TideCore` に置き ubuntu の `swift test` でも検証する（ADR-0002）。
- macOS ジョブはコミットメッセージに `[ios]` を含むときだけ走る（ADR-0002）。
- 実機では L16 まで WeatherKit が使えないため、気象は固定値モックに退避する（ADR-0003）。Detail に由来を出す。
- tide736.net は開発コンテナから到達できない（API 仕様は公開ドキュメントに基づき実装し、CI では固定レスポンスでテスト）。

## 最後に私がやること

L16 で `docs/OWNER_TASKS.md` に手順をまとめる。それまで手作業は不要。
