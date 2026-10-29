# 学習データ

`ml/data/<species_id>/` に写真（jpg/png）を置く。`species_id` は `docs/species.md` の id（kasago, mebaru, ...）。
1クラス 5 枚以上、2 クラス以上で `train-model.yml` が学習し、`Tide/Resources/FishClassifier.mlpackage` を main にコミットする。
写真はアプリの設定画面（L15）から「学習用に書き出す」で取り出せる（端末内の縮小済み写真、魚種 id ごとのフォルダ）。
