# STATUS

## 現在地

L16 まで完了し、最新コミットで CI が全ジョブ緑（SwiftLint・TideCore テスト 55 件・iOS シミュレータ build+test）。スクリーンショット5枚を `docs/screenshots/` に出して目視確認済み。TestFlight にビルド 1 をアップロード済み（2026-10-30）。

## 次のループ

ループは残っていない。次にやること:
1. オーナー: `docs/OWNER_TASKS.md` の手順 6（App Store Connect の TestFlight で内部テストに自分を追加し、iPhone にインストールして確認ポイントを見る）。手順 0〜5 は完了
2. 私: 実機の結果（§8 の修正依頼）を受けて直す。直したら `testflight.yml` を再実行（ビルド番号は自動で +1）

## 既知の問題

- GitHub Actions の停止（課金）はリポジトリを公開にして解消（2026-10-29 23:19 UTC）。公開リポジトリは macOS ランナーも無料枠の制限なし。
- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest、約3分/回）のみ。純粋ロジックは `TideCore` に置き ubuntu の `swift test` でも検証する（ADR-0002）。全ループのコードを CI でコンパイル・テスト済み。
- macOS ジョブはコミットメッセージに `[ios]` を含むときだけ走る（ADR-0002）。
- 実機では L16 の Apple 側設定（WeatherKit）が済むまで気象は固定値モックに退避する（ADR-0003）。Detail の DATA に由来を出す。
- tide736.net は開発コンテナから到達できない。応答形式は GitHub Actions 上のプローブで確認済み（L4）。
- Create ML Tabular（釣れ率 v2）が iOS でコンパイルできない場合は `#if canImport(CreateML)` で自前回帰に落ちる（ADR-0013）。

## 最後に私がやること

`docs/OWNER_TASKS.md` に手順をまとめた（所要約 60 分）。手順 0 → CI 緑化（私）→ 手順 1〜6 → TestFlight で確認ポイントを見る。
