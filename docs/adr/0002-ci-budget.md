# ADR-0002: CI 構成と macOS ランナー予算

日付: 2026-10-29 / 状態: 採用

## 文脈

- リポジトリは private。無料枠では macOS ランナーが月約200分（指示書 §2）。
- 16ループ × （ループ終了＋修正）× 10〜15分 は 200分を超える。
- 指示書 §2 は「超えそうなら macOS ビルドをループ終了時のみに落としてよい（ADR に記録）」と許している。
- 開発コンテナには Xcode も Swift もない（swift.org への通信が遮断）。SwiftUI 部分はローカルで一切コンパイルできない。

## 決定

`ci.yml` を3ジョブに分ける。

1. `lint`（ubuntu）: SwiftLint（`ghcr.io/realm/swiftlint` コンテナ）。毎 push。
2. `core-test`（ubuntu, `swift:6.0-noble` コンテナ）: `TideCore` パッケージの `swift build` / `swift test`。毎 push（`docs/` だけの変更では走らない）。
3. `ios`（macos-latest）: XcodeGen → `xcodebuild build-for-testing` / `test-without-building`（iOS Simulator、署名なし）。**コミットメッセージに `[ios]` を含む push、または `workflow_dispatch` のときだけ走る。** 各ループの終了コミットと CI 修正コミットには必ず `[ios]` を付ける。

補足:
- `docs/` だけの変更は `lint` のみ（指示書 §2 どおり）。
- `ios` ジョブは `timeout-minutes: 20`、`xcodebuild` は `-skipPackagePluginValidation -skipMacroValidation` で検証時間を省く。シミュレータは `xcrun simctl list` から利用可能な最初の iPhone を選ぶ（Xcode バージョン差を吸収）。
- 純ロジック（釣れ率・潮汐・キャッシュ抑止）は Apple フレームワークに依存しない `TideCore` に置き、ubuntu でも毎 push テストする。

## 結果

- main の「常にビルド可能」はループ終了コミット（`[ios]`）で保証する。途中コミットは lint と core-test のみ。
- 月の macOS 使用時間が 150 分を超えた場合は、ios ジョブを `workflow_dispatch` のみに落とす（STATUS に記録）。
