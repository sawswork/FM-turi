# STATUS

## 現在地

L1 開始（2026-10-29）

## 次のループ

L1: リポジトリ初期化、XcodeGen、CI3本、DesignTokens、5タブ＋空画面7つ、ディープリンク。CI緑で完了。

## 既知の問題

- 開発コンテナに Xcode/Swift がないため、SwiftUI 部分の検証は GitHub Actions（macos-latest）のみ。純粋ロジックは `TideCore` パッケージに置き ubuntu の `swift test` でも検証する（ADR-0002）。
- macOS ランナーの無料枠（月約200分）のため、macOS ジョブはコミットメッセージに `[ios]` を含むとき（各ループの終了コミット・CI修正）だけ走る（ADR-0002）。

## 最後に私がやること

L16 で `docs/OWNER_TASKS.md` に手順をまとめる。それまで手作業は不要。
