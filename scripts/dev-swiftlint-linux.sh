#!/usr/bin/env bash
# 開発コンテナ（Linux、Swift ツールチェーン無し）で SwiftLint を動かす。
# 使い方: scripts/dev-swiftlint-linux.sh            （インストール＋lint 実行）
set -euo pipefail
VERSION="${SWIFTLINT_VERSION:-0.57.0}"
if ! command -v swiftlint >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/swiftlint.zip" \
    "https://github.com/realm/SwiftLint/releases/download/${VERSION}/swiftlint_linux.zip"
  unzip -q -o "$tmp/swiftlint.zip" swiftlint -d "$tmp"
  install -m 755 "$tmp/swiftlint" /usr/local/bin/swiftlint
fi
# SourceKit（Swift ツールチェーン）が無いので、構文ベースのルールだけを実行する。
export SWIFTLINT_SWIFT_VERSION="${SWIFTLINT_SWIFT_VERSION:-6.0}"
export SWIFTLINT_DISABLE_SOURCEKIT=1
exec swiftlint lint --strict "$@"
