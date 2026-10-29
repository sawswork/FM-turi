"""魚種分類器の学習（M5 / L13）。

データ: ml/data/<species_id>/*.jpg （species_id は docs/species.md の id）
出力:   <output>/FishClassifier.mlpackage （Core ML、クラス名 = species_id）

転移学習（MobileNetV3-Small, ImageNet 事前学習）→ coremltools で変換。
データが 2 クラス未満なら何もせず正常終了する。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

MIN_IMAGES_PER_CLASS = 5
IMAGE_SIZE = 224


def check() -> int:
    import coremltools as ct  # noqa: PLC0415
    import numpy as np  # noqa: PLC0415
    import torch  # noqa: PLC0415
    import torchvision  # noqa: PLC0415

    print(f"coremltools {ct.__version__}, numpy {np.__version__}, torch {torch.__version__}, torchvision {torchvision.__version__}")
    return 0


def list_classes(data_dir: Path) -> list[str]:
    classes = []
    for child in sorted(data_dir.iterdir()) if data_dir.exists() else []:
        if not child.is_dir():
            continue
        images = [p for p in child.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".heic"}]
        if len(images) >= MIN_IMAGES_PER_CLASS:
            classes.append(child.name)
        else:
            print(f"skip {child.name}: {len(images)} 枚（{MIN_IMAGES_PER_CLASS} 枚以上必要）")
    return classes


def train(data_dir: Path, output_dir: Path, epochs: int) -> int:
    import coremltools as ct  # noqa: PLC0415
    import torch  # noqa: PLC0415
    from torch import nn  # noqa: PLC0415
    from torch.utils.data import DataLoader, random_split  # noqa: PLC0415
    from torchvision import datasets, models, transforms  # noqa: PLC0415

    classes = list_classes(data_dir)
    if len(classes) < 2:
        print(f"学習データが足りません（{len(classes)} クラス）。ml/data/<species_id>/ に写真を置いてください。")
        return 0

    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    train_tf = transforms.Compose([
        transforms.RandomResizedCrop(IMAGE_SIZE, scale=(0.6, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(0.2, 0.2, 0.2),
        transforms.ToTensor(),
        normalize,
    ])
    eval_tf = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMAGE_SIZE),
        transforms.ToTensor(),
        normalize,
    ])
    full = datasets.ImageFolder(str(data_dir), transform=train_tf, is_valid_file=lambda p: Path(p).parent.name in classes)
    class_names = full.classes
    n_val = max(1, int(len(full) * 0.15))
    train_set, val_set = random_split(full, [len(full) - n_val, n_val], generator=torch.Generator().manual_seed(7))
    val_set.dataset = datasets.ImageFolder(str(data_dir), transform=eval_tf, is_valid_file=lambda p: Path(p).parent.name in classes)
    train_loader = DataLoader(train_set, batch_size=16, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_set, batch_size=32, shuffle=False, num_workers=2)

    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, len(class_names))
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    criterion = nn.CrossEntropyLoss(label_smoothing=0.05)

    for epoch in range(epochs):
        model.train()
        total, correct, loss_sum = 0, 0, 0.0
        for images, labels in train_loader:
            optimizer.zero_grad()
            logits = model(images)
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()
            loss_sum += float(loss) * len(labels)
            correct += int((logits.argmax(1) == labels).sum())
            total += len(labels)
        scheduler.step()
        model.eval()
        v_total, v_correct = 0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                v_correct += int((model(images).argmax(1) == labels).sum())
                v_total += len(labels)
        print(f"epoch {epoch + 1}/{epochs} loss={loss_sum / max(total, 1):.3f} "
              f"train_acc={correct / max(total, 1):.3f} val_acc={v_correct / max(v_total, 1):.3f}")

    model.eval()
    example = torch.rand(1, 3, IMAGE_SIZE, IMAGE_SIZE)
    traced = torch.jit.trace(model, example)
    scale = 1 / (0.226 * 255)
    bias = [-0.485 / 0.229, -0.456 / 0.224, -0.406 / 0.225]
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=(1, 3, IMAGE_SIZE, IMAGE_SIZE), scale=scale, bias=bias,
                             color_layout=ct.colorlayout.RGB)],
        classifier_config=ct.ClassifierConfig(class_names),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
    )
    mlmodel.short_description = "Tide 魚種分類（付録B の id）"
    mlmodel.author = "Tide"
    output_dir.mkdir(parents=True, exist_ok=True)
    out = output_dir / "FishClassifier.mlpackage"
    mlmodel.save(str(out))
    (output_dir / "classes.json").write_text(json.dumps(class_names, ensure_ascii=False, indent=2))
    print(f"saved {out} ({len(class_names)} classes, {len(full)} images)")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="環境確認のみ")
    parser.add_argument("--data", default="ml/data", help="学習データのディレクトリ")
    parser.add_argument("--output", default="build/ml", help="出力ディレクトリ")
    parser.add_argument("--epochs", type=int, default=8)
    args = parser.parse_args(argv)
    if args.check:
        return check()
    return train(Path(args.data), Path(args.output), args.epochs)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
