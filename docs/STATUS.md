# STATUS

## 現在地

L16 まで実装完了（2026-10-29）。**ただし L5〜L16 は CI 未検証**（GitHub Actions が課金状態で停止中）。

## 次のループ

ループは残っていない。次にやること:
1. オーナー: `docs/OWNER_TASKS.md` の手順 0（Actions の課金状態を直して CI を手動実行）
2. 私（「続けて」で再開）: 最新コミットの CI（SwiftLint 全ルール・TideCore テスト・iOS build+test）を緑にする。赤の内容は CHANGELOG に「L16 修正」として追記
3. オーナー: OWNER_TASKS の手順 1〜6（Apple 側の設定・Secrets・TestFlight）
4. 私: TestFlight の結果（§8 の修正依頼）を受けて直す

## 既知の問題

- **【要対応・オーナー】GitHub Actions が止まっている（2026-10-29 17:11 UTC〜）。** 全ジョブが「The job was not started because recent account payments have failed or your spending limit needs to be increased」で即失敗する。直し方は `docs/OWNER_TASKS.md` 手順 0。
- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest、約3分/回）のみ。純粋ロジックは `TideCore` に置き ubuntu の `swift test` でも検証する（ADR-0002）。L1〜L4 は CI 緑で確認済み。L5 以降の Swift コードは未コンパイル（文法・型のエラーがあり得る）。
- macOS ジョブはコミットメッセージに `[ios]` を含むときだけ走る（ADR-0002）。
- 実機では L16 の Apple 側設定（WeatherKit）が済むまで気象は固定値モックに退避する（ADR-0003）。Detail の DATA に由来を出す。
- tide736.net は開発コンテナから到達できない。応答形式は GitHub Actions 上のプローブで確認済み（L4）。
- Create ML Tabular（釣れ率 v2）が iOS でコンパイルできない場合は `#if canImport(CreateML)` で自前回帰に落ちる（ADR-0013）。

## 最後に私がやること

`docs/OWNER_TASKS.md` に手順をまとめた（所要約 60 分）。手順 0 → CI 緑化（私）→ 手順 1〜6 → TestFlight で確認ポイントを見る。
