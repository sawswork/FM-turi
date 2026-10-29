# CHANGELOG

ループごとの記録（指示書 §7 の形式）。新しいものが上。

## L5 2026-10-29
やったこと:
- 釣れ率 v1（TideCore.FishingScore）: 潮25＋マズメ20＋風15＋気圧15＋水温15＋波10。内訳を必ず保持。係数は ADR-0005
- 魚種マスタ（付録B）を TideCore.Species に定数化
- Home: リング240＋「72」＋点5つ、4条件メーター（wind/wave/drop/pressure）、24時間バー（選択中の日の毎正時の釣れ率、現在時=橙）
- Detail（下からのシート）: 場所行、数値グリッド10項目、月相7つ、内訳6行（25点満点に対する割合、50%以上=橙）、取得時刻と由来の行
- リング／4条件のタップで Detail、chevron-down で閉じる
- 注: GitHub Actions が課金状態で停止中のため CI 未検証（復旧後に最新コミットで検証する）
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [Home] 起動 → 中央に大きな数字とリング、下に点5つ（数字÷20 が橙）、4条件のアイコンとメーター
- [Home] リングをタップ → 下から Detail。TIDE/WIND/WAVE/PRESS/SST/AIR/SUNRISE/SUNSET/HIGH/LOW と月相7つ、内訳6行
- [Detail] 内訳 → 点数の高い順、バーの合計が中央の数字と一致。一番下に DATA（取得時刻と由来）
仕様から外れた判断: ADR-0005（係数・メーターの意味・月相7つの並び・DATA 行）

## L4 2026-10-29
やったこと:
- tide736 API（get_tide.php, rg=day）の URL 生成・解析（TideCore）。同梱の港一覧 712 件（tide736 の link 情報から生成、度分→十進変換）で最寄り港を選ぶ
- 日出・日没（NOAA 式）、月齢・潮回り（TideCore、tide736 の値を優先し、無ければ端末内計算）
- TideStore: 港×日のキーで SwiftData にキャッシュ（予測値なので再取得しない）。シミュレータ・CI は正弦波モック
- Home: 日付チップ3つ（今日=橙）＋月相グリフ＋潮回り、3日横スクロール潮位グラフ（マズメ帯・太陽弧・現在線・現在点・時刻）
- プローブ用の一時ワークフローは削除（ワークフローは3本に戻した）
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [Home] 起動 → 日付チップ「M/d 曜」×3、右に月相と潮回り（例「中潮」）
- [Home] 潮位グラフを横スクロール → 3日分、今日だけ橙の現在線と現在点、時刻ラベル
- [Home] 日付チップをタップ → グラフがその日へスクロールし、チップが橙になる
仕様から外れた判断: ADR-0004（日付チップは「今日」ではなく「選択中」を橙にする。初期選択=今日）

## L3 2026-10-29
やったこと:
- 現在地取得（CLLocationUpdate.liveUpdates、拒否・未測位時は城ヶ島を既定点に）
- Home 上部帯: 最寄りの登録済み釣り場名を位置ピルに表示、右に round36(dots)
- WeatherProvider / MarineProvider プロトコル。WeatherKit 実装と Open-Meteo Marine 実装、シミュレータ・CI は固定値モック
- SwiftData モデル（Spot / WeatherRecord / MarineRecord）と ConditionsStore。同一地点0.01°・同一時間帯は再取得しない
- 初回起動時に付録A の登録済み4釣り場を投入
- ユニットテスト: キャッシュキー、Open-Meteo 解析、再取得抑止（TideCore=Linux、TideTests=シミュレータ）
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [Home] 起動 → 左上のピルに最寄りの釣り場名（既定は「城ヶ島 西側」）、右上に … の丸ボタン
- [Home] 位置情報の許可ダイアログ → 許可すると最寄り釣り場に切り替わる
仕様から外れた判断: ADR-0003（初期データ4点・既定点・取得失敗時の退避）

## L2 2026-10-29
やったこと:
- 共通部品: LocationPill / RoundButton / TabBarView / MeterView / MoonGlyph / RingView / TopBarView（すべて #Preview 付き）
- ComponentsGallery（部品を1画面で見るプレビュー）
- 月相グリフは月齢から影の形を計算（新月→満月→新月）
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [Home] 下部タブバー → 5項目が等間隔、中央カメラだけ橙の丸、選択中が白
- [Home] 左上ピル → 橙のピン＋釣り場名、h36 の角丸
仕様から外れた判断: なし

## L1 2026-10-29
やったこと:
- リポジトリ初期化、CLAUDE.md / docs（SPEC, species, STATUS, ADR）
- XcodeGen project.yml（Tide / TideTests / TideCore ローカルパッケージ、iOS 18.0、Swift 6）
- CI 3本: ci.yml（SwiftLint・TideCore Linux テスト・macOS シミュレータ build+test）、testflight.yml（Secrets 無しはスキップ）、train-model.yml（環境確認）
- DesignTokens（A-0 の色・フォント・寸法）と SwiftLint による色の直書き禁止
- 5タブ＋空画面7つ（Home / Spots / Catch / Detail / Zukan / Tackle / Widgets）
- ディープリンク tide://catch → Catch タブ
確認ポイント（最後に私が実機で見るところ、最大3つ）:
- [全体] 起動 → 黒背景に角丸のタブバー、タブをタップで切替
- [全体] Safari で tide://catch を開く → アプリが Catch タブで開く
仕様から外れた判断: ADR-0002（macOS CI はループ終了コミットのみ）
