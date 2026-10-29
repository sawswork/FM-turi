# オーナーの手作業（1回だけ、iPad の Safari で完結）

所要約 60 分（Apple 側の処理待ちを除く）。順番どおりに進めてください。
途中で赤（失敗）が出たら、新しいセッションで「続けて」と送ってください。STATUS.md を読んで私が直します。

## 0. GitHub Actions を動かせるようにする（必須・最初に）
2026-10-29 17:11 UTC から GitHub Actions の全ジョブが「recent account payments have failed or your spending limit needs to be increased」で止まっています。
1. https://github.com/settings/billing を開く
2. 「Payment information」で支払い方法を確認・更新する（失敗している請求があれば再試行）
3. 「Spending limits」→ Actions の上限を確認する（$0 で止まっている場合は上限を上げるか、無料枠内で動くよう「Limit spending」のまま OK にする）
4. https://github.com/sawswork/FM-turi/actions → 左の「CI」→ 右上「Run workflow」→ Branch main → Run workflow
5. 緑になれば次へ。赤なら新しいセッションで「続けて」と送る（L5 以降は CI 未検証なので、ここで直す作業が発生します）

## 1. Apple Developer: App ID と App Group と WeatherKit
前提: Apple Developer Program に加入済み（年額）。https://developer.apple.com/account で以下。
1. 「Certificates, Identifiers & Profiles」→「Identifiers」→「+」→「App Groups」→ Description: Tide、Identifier: `group.jp.tide.app` → Continue → Register
2. 「Identifiers」→「+」→「App IDs」→ App → Description: Tide、Bundle ID: Explicit `jp.tide.app`
   - Capabilities: 「App Groups」にチェック → Edit/Configure で `group.jp.tide.app` を選ぶ
   - 「WeatherKit」にチェック（Capabilities タブ）。さらに上の「App Services」タブでも「WeatherKit」にチェック
   - Continue → Register
3. もう一度「+」→「App IDs」→ App → Description: Tide Widgets、Bundle ID: Explicit `jp.tide.app.widgets`
   - 「App Groups」にチェック → `group.jp.tide.app` を選ぶ → Register
4. 「Membership details」（https://developer.apple.com/account#MembershipDetailsCard）で Team ID（英数字10桁）を控える → `TEAM_ID`

## 2. App Store Connect にアプリを作る
1. https://appstoreconnect.apple.com →「マイApp」→「+」→「新規App」
2. プラットフォーム iOS、名前「Tide」、プライマリ言語「日本語」、バンドルID `jp.tide.app`、SKU `tide-ios`、ユーザアクセス「フルアクセス」→ 作成
3. 「App情報」「価格と配信状況」は後回しで可（TestFlight には不要）

## 3. App Store Connect API キー
1. https://appstoreconnect.apple.com/access/integrations/api →「チームキー」→「+」
2. 名前「Tide CI」、アクセス「App Manager」→ 生成
3. 表示される「Issuer ID」を控える → `ASC_ISSUER_ID`
4. 行の「キーID」を控える → `ASC_KEY_ID`
5. 「APIキーをダウンロード」（1回しかできません）。iPad では「ファイル」の「ダウンロード」に `AuthKey_XXXX.p8` が入る
6. 「ファイル」で `.p8` を長押し →「クイックルック」→ 本文を全選択してコピー（`-----BEGIN PRIVATE KEY-----` から `-----END PRIVATE KEY-----` まで全部）→ `ASC_KEY_P8`
   （クイックルックで開けない場合: 「共有」→「メモ」に貼り付けてからコピー）

## 4. GitHub に Secrets を登録
https://github.com/sawswork/FM-turi/settings/secrets/actions →「New repository secret」を4回:
| Name | Value |
|---|---|
| `ASC_KEY_ID` | 手順3-4 のキーID |
| `ASC_ISSUER_ID` | 手順3-3 の Issuer ID |
| `ASC_KEY_P8` | 手順3-6 の .p8 の本文（複数行のまま） |
| `TEAM_ID` | 手順1-4 の Team ID |

## 5. TestFlight へアップロード
1. https://github.com/sawswork/FM-turi/actions → 左の「TestFlight」→「Run workflow」→ Branch main → Run workflow
2. 20〜40 分待つ。緑なら成功。「スキップ」と出たら Secrets の名前を確認
3. 赤なら、失敗したステップの赤い行をコピーして新しいセッションで「続けて」と送る

## 6. iPhone で確認
1. App Store Connect →「マイApp」→ Tide →「TestFlight」タブ。処理中（10〜30分）のあとビルドが出る
2. 「内部テスト」→「+」でグループを作り、自分を追加
3. iPhone に「TestFlight」App を入れ、届いたメールか TestFlight App から Tide をインストール
4. 下の「確認ポイント」を見る。気づいたことは §8 の形式（`[画面名] 見た目|動き|データ: 何が / どうあるべきか`）で新しいセッションに送る

## 7. （任意）スクリーンショットと公開
1. Actions →「CI」→「Run workflow」→ screenshots にチェック → Run。成果物 `screenshots` の zip をダウンロード（iPad の「ファイル」で展開）
2. App Store Connect の App 情報・スクリーンショット・説明は `docs/APP_STORE.md` の文面を貼る

## 8. （任意）魚種モデルの学習
1. アプリの設定（Home の …）→「学習用に書き出す」→ ZIP を「ファイル」に保存 → 展開
2. GitHub の `ml/data/` に魚種 id ごとのフォルダで写真をアップロード（Add file → Upload files。1魚種 5 枚以上、2魚種以上）
3. Actions →「Train Model」→ Run workflow（check_only はオフ）→ 30 分ほどで `Tide/Resources/FishClassifier.mlpackage` が main にコミットされる → 手順5 をもう一度

## 確認ポイント（画面ごと）
CHANGELOG の確認ポイントを画面別にまとめたもの。

### 初回起動
- 黒い全画面の注意書き → ✓ で閉じ、次回起動では出ない
- 位置情報の許可ダイアログ → 許可すると最寄りの釣り場に切り替わる

### Home
- 左上のピルに最寄りの釣り場名（既定「城ヶ島 西側」）、右上に … → 設定
- 中央に大きな数字とリング、下に点5つ（数字÷20 が橙）、4条件のアイコンとメーター
- 日付チップ「M/d 曜」×3、右に月相と潮回り。チップをタップでグラフがその日へ
- 潮位グラフを横スクロール → 3日分。今日だけ橙の現在線・現在点・時刻
- 24時間バー。現在時が橙、60以上が白
- 気象警報があるときだけ橙のピル
- 下部タブバー: 5項目、中央カメラだけ橙の丸

### Detail（リングか4条件をタップ）
- TIDE/WIND/WAVE/PRESS/SST/AIR/SUNRISE/SUNSET/HIGH/LOW、月相7つ、内訳6行（点数順、合計=中央の数字）
- 一番下 DATA: 取得時刻と由来（weatherkit / open-meteo / tide736 / harmonic / mock）。2回目以降の起動で harmonic

### Catch（中央のカメラ）
- 写真枠タップ → 写真ライブラリ。選ぶと表示、右上チップに撮影日時、候補3つが入れ替わる、右下リングが確度
- 500円玉が写っていればサイズに推定値、無ければ空で入力できる
- タックルピルをタップで巡回。✓ で図鑑へ

### 図鑑
- 保存した魚のカードが白塗り、右上に匹数、「n / 12」とリング。最大記録だけ橙
- カードをタップ → 記録一覧

### 釣り場
- 地図に灰色の候補点と登録済みの数字バッジ（最寄りが橙）。候補点タップ → 白いポップアップ → ＋ で登録
- リストは近い順、風向の矢印、右端に釣れ率

### Tackle
- 円をタップで橙（選択中）。ステッパーの −/+ で在庫。行列は使った組み合わせ

### ウィジェット
- ホーム画面に「Tide」小2種・中1種・大1種。大の −/+ はアプリを開かずに減る
- カメラピル → Catch、book → 図鑑、hook → Tackle

### 設定（Home の …）
- 釣れ率の配点（v1: 25/20/15/15/15/10）。釣果10件以上で「学び直す」→ v2
- 学習用に書き出す（ZIP）、すべて削除（確認あり）、注意書き
