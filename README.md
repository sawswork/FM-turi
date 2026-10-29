# Tide

潮の動き・マズメ・風・気圧・水温・波から「釣れ率」を出す、iPhone 専用・完全ローカルの釣りアプリ。
Mac を持たないオーナーの代わりに、設計・実装・テスト・CI・配布はすべて Claude Code が GitHub Actions 上で行う。

- 指示書: `CLAUDE.md` / 画面仕様: `docs/SPEC.md` / 魚種: `docs/species.md`
- 現在地と次の作業: `docs/STATUS.md` / ループの記録: `CHANGELOG.md` / 判断: `docs/adr/`
- オーナーの手作業（Secrets・Apple 設定・TestFlight）: `docs/OWNER_TASKS.md`
- App Store の文面: `docs/APP_STORE.md`

## 構成
- `project.yml` — XcodeGen（`.xcodeproj` はコミットしない）
- `Tide/` — アプリ（App / Core / Features / Data / Resources）
- `TideWidgets/` — WidgetKit 拡張（App Group でアプリと同じ SwiftData を共有）
- `TideCore/` — Apple フレームワーク非依存の Swift Package（釣れ率・潮汐・キャッシュ・解析。Linux でもテスト）
- `TideTests/` `TideUITests/` — シミュレータのテストとスクリーンショット
- `ml/` — 魚種分類器の学習（`train-model.yml`）
- `fastlane/` — TestFlight 配布（`testflight.yml`）

## CI
- `ci.yml`: push ごとに SwiftLint と TideCore の Linux テスト。コミットメッセージに `[ios]` があるとき（各ループの終了時）に macOS でシミュレータ build + test。`workflow_dispatch` の screenshots で 5 タブの PNG。
- `testflight.yml`: 手動。Secrets（`ASC_KEY_ID` `ASC_ISSUER_ID` `ASC_KEY_P8` `TEAM_ID`）が無ければスキップ。
- `train-model.yml`: 手動。`ml/data` から Core ML モデルを学習して main にコミット。
