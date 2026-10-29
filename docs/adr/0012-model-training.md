# ADR-0012: 魚種分類モデルの学習経路

日付: 2026-10-29 / 状態: 採用

## 文脈

指示書 §4: 「M5 で train-model.yml により自前 Core ML 分類器を学習・同梱し、候補の確度を表示」。写真は完全ローカル（端末内）なので、学習データはオーナーが明示的に取り出してリポジトリに置く必要がある。

## 決定

1. 学習データは `ml/data/<species_id>/*.jpg`。端末からの取り出しは設定画面（L15）の「学習用に書き出す」（魚種 id ごとのフォルダを ZIP にしてファイル App へ保存）。GitHub へは iPad の Safari からアップロードできる。
2. `train-model.yml`（手動）: MobileNetV3-Small（ImageNet 事前学習）を転移学習し、coremltools で `FishClassifier.mlpackage`（mlprogram, iOS17+, クラス名=species_id）に変換。成果物をアップロードし、`Tide/Resources/` に main へコミットする（`contents: write`）。データが足りなければ何もしない。
3. アプリは同梱モデルがあれば VNCoreMLRequest（確度 = softmax）、無ければ従来の汎用分類＋付録B マッピング。Core ML のクラス自動生成は `COREML_CODEGEN_LANGUAGE=None` で無効化し、`FishClassifier.mlmodelc` を URL で読む。
4. 確度の表示は Catch の AI リング（既存）。数値ラベルは足さない。

## 結果

- 完全ローカルの原則を保ったまま、オーナーの操作で段階的にモデルを育てられる。
- `.mlpackage` をリポジトリに置くためリポジトリは大きくなる（MobileNetV3-Small は約 10MB）。
