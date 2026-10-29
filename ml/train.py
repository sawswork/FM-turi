"""魚種分類器の学習スクリプト（M5/L13 で本実装）。

L1 時点では環境確認（--check）だけを行う。
"""

from __future__ import annotations

import argparse
import sys


def check() -> int:
    import coremltools as ct  # noqa: PLC0415
    import numpy as np  # noqa: PLC0415

    print(f"coremltools {ct.__version__}, numpy {np.__version__}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="環境確認のみ")
    parser.add_argument("--output", default="build/ml", help="出力ディレクトリ")
    args = parser.parse_args(argv)
    if args.check:
        return check()
    print("学習データがまだありません（L13 で実装）。", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
