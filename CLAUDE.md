# 釣りアプリ「Tide」 ループエンジニアリング 起動指示書

これはこのリポジトリで最初に送る唯一のメッセージです。あなた（Claude Code）はこの文書を受け取ったら、まず §0 を実行し、その後は §6 のループ手順に従って、全ループが終わるまで自走してください。私に何も聞かず、何も頼まず、最後まで進めます。私の手作業は一番最後（§9）にまとめて1回だけです。

## §0 最初にやること（このメッセージを受け取った直後）

1. この文書全文を `CLAUDE.md` として保存する（これ以降、毎セッションの最初に自動で読まれる）。
2. 付録A（画面仕様）を `docs/SPEC.md`、付録B（魚種）を `docs/species.md` に分けて保存する。
3. `docs/STATUS.md` を作る（現在地／次のループ／既知の問題／最後に私がやること、の4見出し）。
4. `docs/adr/0001-architecture.md` を書く（§4 の技術選定を理由付きで記録）。
5. ループ1を開始する（§5）。

以後、私が新しいセッションで「続けて」とだけ送ったら、`docs/STATUS.md` を読んで次のループから再開すること。

## §1 絶対ルール

1. 私はコードを書かない・読まない・レビューしない。設計判断・実装・テスト・CI・リリースはすべてあなたが行う。
2. Issue も PR も作らない。ループの記録は `docs/STATUS.md` と `CHANGELOG.md` だけ。作業は `main` に直接コミットする（1ループ＝1つ以上のコミット、メッセージ先頭に `L{n}:`）。
3. 私に質問も依頼もしない。迷ったら §3 の優先順位で自分で決め、`docs/adr/NNNN-*.md` に1枚残して進む。私の手作業（Secrets登録・Apple側設定・TestFlight確認）が必要になる作業は、すべて最終ループ（L16）まで後回しにし、それまでは署名なしビルドで進める。
4. 仕様外の機能・文字ラベル・色を足さない。足したいものは `docs/PROPOSALS.md` に書くだけ。
5. CIが赤のまま次へ進まない。mainは常にビルド可能。
6. 完全ローカル。自前サーバー・外部DB・解析SDK・広告SDKは入れない。通信は §4 の公開APIとAppleのサービスだけ。
7. 毎ループ終了時に `CHANGELOG.md` と `docs/STATUS.md` を更新。私はこの2枚だけを見る。
8. 1セッションで止まらない。ループが終わったら即、次のループへ。止まるのは (a) L16 まで全部終わった (b) 私が「止めて」と言った (c) セッションの上限、の3つだけ。
9. 仕様が矛盾している場合も止まらない。付録Aの数値を優先し、矛盾の内容と選んだ解釈を ADR に書いて進む。

## §2 開発環境（私はMacを持たない。iPadとiPhoneのみ）

- アプリ名: Tide（仮）。Bundle ID: `jp.tide.app`（私が変えたければSTATUSで指示）。最小OS: iOS 18.0。iPhoneのみ。
- Xcodeプロジェクトは XcodeGen（`project.yml`）で生成。`.xcodeproj` はコミットしない。
- Swift 6 / SwiftUI / SwiftData / WidgetKit / AppIntents / MapKit / WeatherKit / Vision / Core ML。
- GitHub Actions ワークフロー3本:
  - `ci.yml`: mainへのpushごと。macos-latest で `xcodebuild build test`（シミュレータ、署名なし）＋ SwiftLint。`docs/` だけの変更なら ubuntu でLintのみ。
  - `testflight.yml`: 手動トリガー（workflow_dispatch）のみ。Fastlane + App Store Connect API Key で Archive → TestFlight。Secrets未登録なら「スキップ」と出して失敗させない。私が最後に1回動かす。
  - `train-model.yml`: ubuntu。Python + coremltools で `.mlmodel` 生成（M5以降、手動トリガー）。
- 署名: Fastlane、自動署名、`-allowProvisioningUpdates`。match は使わない。
- 私の手作業（L16でまとめて1回）: Secrets `ASC_KEY_ID` `ASC_ISSUER_ID` `ASC_KEY_P8` `TEAM_ID` の登録、App ID 登録、WeatherKit Capability 有効化、App Store Connect にアプリ作成、`testflight.yml` の手動実行、TestFlightでの確認。これらの手順は L16 で `docs/OWNER_TASKS.md` に、iPadのSafariだけで完了できる形で書く。それまでは一切触れない。
- WeatherKit が未設定でもビルドが通るよう、天気取得は `WeatherProvider` プロトコルで抽象化し、CIとシミュレータでは固定値のモック実装を使う。
- macOSランナーの無料枠は月約200分。1ビルドを15分以内に収める。超えそうなら macOSビルドを「ループ終了時のみ」に落としてよい（ADRに記録）。

## §3 優先順位（衝突したらこの順）

1. 安全（潮汐は「航海の用に使用しないでください」の注意書きを初回起動と設定画面に表示。気象警報を表示）
2. 完全ローカル
3. 付録Aの画面仕様への忠実さ（数値そのまま）
4. 釣れ率の説明可能性（内訳が必ず出る）
5. 開発速度

## §4 データ・技術の確定事項

- アーキテクチャ: 機能単位 `Features/{Home,Spots,Catch,Detail,Zukan,Tackle,Widgets}`、共通 `Core/`（DesignTokens, Icons, Components）、`Data/`（SwiftDataモデル、API client、キャッシュ）。
- デザイントークン: 付録Aの色・角丸・フォント・間隔を `Core/DesignTokens.swift` の1ファイルに定数化。画面はこの定数しか使わない。
- アイコン: SF Symbols を第一候補。該当がないもの（釣り針・シンカー・魚）は `Core/Icons/` に Path で描く。
- 潮汐・日出没・月齢・潮回り: M1 は tide736 API（https://tide736.net ）で取得し SwiftData にキャッシュ。M3 で調和定数ベースの端末内計算へ置換（主要分潮 M2,S2,K1,O1,N2,K2,P1,Q1 以上）。
- 風・気圧・気温・警報: WeatherKit。波高・周期・うねり・海水温: Open-Meteo Marine API（https://marine-api.open-meteo.com ）。取得値は必ず SwiftData に保存し、同一地点・同一時刻の再取得をしない。オフライン時はキャッシュを表示し、取得時刻を Detail に出す。
- 釣り場候補: MapKit MKLocalSearch で「漁港」「堤防」「岬」「磯」「港」を検索し端末内キャッシュ。加えて tide736 の港一覧を候補点にする。登録済みは SwiftData。釣り禁止判定はしない旨を注意書きに入れる。
- 魚種判定: M2 は Vision の汎用画像分類＋付録Bの魚種名マッピングで「候補3つ＋ユーザー確定」。確定した画像はアプリ内に縮小保存（長辺1024）。M5 で `train-model.yml` により自前 Core ML 分類器を学習・同梱し、候補の確度を表示。
- サイズ推定: Vision で基準物（メジャー・500円硬貨）を検出して換算。LiDAR機は ARKit の距離で補助。推定できなければ数字を空にしてユーザー入力。
- 釣れ率 v1（0～100 整数）: 潮の動き(0-25) + マズメ距離(0-20) + 風(0-15 強いほど減点) + 気圧変化(0-15 下降で加点) + 水温適性(0-15 付録Bの適温帯) + 波(0-10 高いほど減点)。内訳を必ず保持し Detail に出す。v2（M6）は自分の釣果ログで係数を再学習（Create ML Tabular を端末内で実行）。
- ウィジェット: WidgetKit。−/+ は AppIntents で在庫を直接更新。カメラは Catch 画面へのディープリンク（`tide://catch`）。
- ログ: `os.Logger` のみ。クラッシュ収集SDKは入れない。
- テスト: 釣れ率の計算、潮汐計算、キャッシュの再取得抑止は必ずユニットテスト。

## §5 マイルストーンとループ（1ループは2～4日で終わる粒度）

M0 骨組み
- L1: リポジトリ初期化、XcodeGen、CI3本、DesignTokens、5タブ＋空画面7つ、ディープリンク。CI緑で完了。
- L2: 共通部品（位置ピル・丸ボタン・タブバー・メーター・月相グリフ・リング）をプレビュー付きで実装。

M1 情報取得
- L3: 位置取得、釣り場ピル、WeatherKit、Open-Meteo Marine、SwiftDataキャッシュ。
- L4: tide736、日出没、月齢、潮回り、Homeの3日横スクロール潮位グラフ。
- L5: 釣れ率v1、リング、4条件メーター、24hバー、Detailシート（内訳付き）。

M2 記録
- L6: Catch画面、写真選択、EXIF、その時刻の条件を紐付けて保存。
- L7: Vision候補3つ＋確定、図鑑画面。
- L8: サイズ推定、使用タックルの紐付け。

M3 釣り場
- L9: MapKit候補点、登録、ポップアップ、リスト、各釣り場の釣れ率。
- L10: 潮汐の端末内計算へ置換、注意書き。

M4 ウィジェット
- L11: 小・中ウィジェット。
- L12: 大ウィジェット（−/+のAppIntents）、Tackle画面と在庫同期。

M5 AI強化
- L13: `train-model.yml`、蓄積データからの学習、`.mlmodel` 同梱、確度表示。
- L14: シンカー×フック行列、使用頻度。

M6 仕上げ
- L15: 釣れ率v2、気象警報表示、設定画面（注意書き・データ削除）。
- L16: アイコン、スクショ、App Store提出物、docs整備、`docs/OWNER_TASKS.md`（私の手作業手順）。ここで初めて私に声をかける。

## §6 ループ手順（毎ループ同じ）

1. `docs/STATUS.md` を読み、次のループを特定する。私がチャットで修正を頼んでいればそれを先頭に入れる。
2. `docs/STATUS.md` の「現在地」に `L{n} 開始` と書いてコミット。
3. 実装 → ユニットテスト → SwiftLint → mainへpush。
4. CIが緑になるまで直す。3回直して赤なら原因をADRに書き、スコープを縮めて緑にする。
5. `CHANGELOG.md` に §7 の形式で追記、`docs/STATUS.md` を更新。
6. 私に報告せず、即 次のループへ（§1-8）。

## §7 ループ記録（CHANGELOG.md の固定形式）

```
## L{n} {日付}
やったこと:
- …
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [画面] 操作 → 期待される見え方
仕様から外れた判断: ADR-{NNNN} / なし
```

## §8 私からの修正依頼（あれば、チャットで送る）

```
[画面名] 見た目|動き|データ: 何が / どうあるべきか。
```

あなたはこれを受けたら次のループの先頭に修正を入れ、終わったらまた自走に戻る。

## §9 完了条件と私の出番

L16 まで終わったら `docs/OWNER_TASKS.md` を書き、そこで初めて私に報告する。報告はこの3行だけ:

1. 「全ループ完了。OWNER_TASKS.md の手順（所要約○分）をやってください」
2. 手順を終えたら `testflight.yml` を手動実行すること
3. 届いたビルドで見るところ（CHANGELOG の確認ポイントを画面ごとにまとめたもの）

今すぐ §0 を実行し、L1 から自走を開始してください。このメッセージへの返事は不要です。

---

付録A（画面仕様）は `docs/SPEC.md`、付録B（魚種マスタ）は `docs/species.md` に保存してある。画面を実装するときは必ず `docs/SPEC.md` の数値をそのまま使うこと。

## 作業メモ（Claude Code 自身のための補足。指示書本文ではない）

- 作業ブランチは `main`。コミットメッセージは `L{n}: ...` で始める。
- 現在地と次のループは `docs/STATUS.md`。ループ記録は `CHANGELOG.md`。判断記録は `docs/adr/`。
- 開発コンテナには Xcode がない。純粋ロジック（釣れ率・潮汐計算・キャッシュ抑止）は `TideCore` という Apple フレームワーク非依存の Swift Package に置き、Linux の `swift test` でも検証できるようにする。SwiftUI 部分は CI（macos-latest）で検証する。
