# ADR-0001: アーキテクチャと技術選定

日付: 2026-10-29 / 状態: 採用

## 文脈

指示書 §2・§4 に従い、iPhone 専用・iOS 18.0+・完全ローカルの釣りアプリ「Tide」を、Mac を持たないオーナーの代わりに GitHub Actions だけでビルド・配布する。

## 決定

| 項目 | 決定 | 理由 |
|---|---|---|
| 言語/UI | Swift 6（言語モード 6）、SwiftUI | 指示書指定。strict concurrency で WidgetKit/AppIntents との境界が明確になる |
| 永続化 | SwiftData | 指示書指定。外部DB禁止。ウィジェットとは App Group 上の同一ストアを共有 |
| プロジェクト生成 | XcodeGen `project.yml`、`.xcodeproj` は非コミット | 指示書指定。差分がレビュー可能でマージ衝突が起きない |
| 構成 | `Tide/App`（起動・タブ・ディープリンク）、`Tide/Core`（DesignTokens, Icons, Components）、`Tide/Features/{Home,Spots,Catch,Detail,Zukan,Tackle,Widgets}`、`Tide/Data`（SwiftData モデル・API client・キャッシュ）、`TideCore/`（SwiftPM, Apple フレームワーク非依存の純ロジック） | 指示書 §4 の機能単位構成。`TideCore` を分離するのは、釣れ率・潮汐計算・キャッシュ抑止を Linux でもユニットテストできるようにするため（開発コンテナに Xcode がない） |
| デザイントークン | `Tide/Core/DesignTokens.swift` 1ファイル。色・角丸・フォント・間隔はすべて定数。画面は直接の16進色・数値を書かない | 指示書 §4。SwiftLint のカスタム正規表現ルールで `Color(hex:` の直書きを禁止 |
| アイコン | SF Symbols 優先。hook/sinker/fish/wind 等は `Core/Icons/` に `Shape` として Path 描画 | 指示書 §4。線幅・端丸を仕様どおり制御できる |
| 潮汐 | M1: tide736 API → SwiftData キャッシュ。M3: 調和定数（M2,S2,K1,O1,N2,K2,P1,Q1）による端末内計算に置換 | 指示書 §4。端末内計算は `TideCore` に置きテスト可能にする |
| 気象 | `WeatherProvider` プロトコル。本番は WeatherKit、CI/シミュレータは固定値モック。波・海水温は Open-Meteo Marine | 指示書 §2・§4。WeatherKit の Capability 未設定でもビルドできる |
| キャッシュ | 同一地点（緯度経度を 0.01° に丸め）・同一時刻（時間単位）のキーで SwiftData に保存。キー一致なら再取得しない。判定ロジックは `TideCore` に置く | 指示書 §4。再取得抑止はユニットテスト必須 |
| 釣れ率 | `TideCore.FishingScore`: 潮25+マズメ20+風15+気圧15+水温15+波10=100。内訳を `Breakdown` 構造体で保持 | 指示書 §4。説明可能性（§3-4）を型で担保 |
| ウィジェット | WidgetKit + AppIntents。在庫更新はApp Group 共有の SwiftData を直接書く | 指示書 §4 |
| ログ | `os.Logger` のみ | 指示書 §4 |
| CI | GitHub Actions 3本（ci / testflight / train-model）。詳細は ADR-0002 | 指示書 §2 |
| 署名 | Fastlane、自動署名、`-allowProvisioningUpdates`、App Store Connect API Key。match 不使用 | 指示書 §2 |
| Bundle ID | `jp.tide.app`（App Group: `group.jp.tide.app`） | 指示書 §2 |

## 結果

- 画面コードは `DesignTokens` と `Core/Components` だけで組み立てる。
- ロジックは可能な限り `TideCore` に寄せ、SwiftUI 層は薄く保つ。
