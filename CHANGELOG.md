# CHANGELOG

ループごとの記録（指示書 §7 の形式）。新しいものが上。

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
