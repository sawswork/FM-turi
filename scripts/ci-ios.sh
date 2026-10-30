#!/usr/bin/env bash
# iOS シミュレータ向けの署名なしビルド＋テスト（GitHub Actions macos-latest 用）。
set -euo pipefail

XCODEGEN_VERSION="${XCODEGEN_VERSION:-2.42.0}"
PROJECT="Tide.xcodeproj"
SCHEME="Tide"
DERIVED="build/DerivedData"

echo "::group::XcodeGen"
if ! command -v xcodegen >/dev/null 2>&1; then
  if curl -fsSL -o /tmp/xcodegen.zip \
      "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"; then
    rm -rf /tmp/xcodegen && mkdir -p /tmp/xcodegen
    unzip -q -o /tmp/xcodegen.zip -d /tmp/xcodegen
    export PATH="/tmp/xcodegen/xcodegen/bin:$PATH"
  else
    echo "release の取得に失敗。brew でインストールします"
    brew install xcodegen
  fi
fi
xcodegen --version
xcodegen generate --spec project.yml
echo "::endgroup::"

echo "::group::Simulator"
xcodebuild -version
UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
best = None
for runtime, devs in devices.items():
    if "iOS" not in runtime:
        continue
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    version = (int(match.group(1)), int(match.group(2))) if match else (0, 0)
    for dev in devs:
        name = dev.get("name", "")
        if not dev.get("isAvailable", False) or not name.startswith("iPhone"):
            continue
        # 通常は素の iPhone（軽い）。スクリーンショット時は 6.9 インチの Pro Max を優先
        import os
        if os.environ.get("PREFER_PRO_MAX") == "1":
            plain = 1 if "Pro Max" in name else 0
        else:
            plain = 1 if re.fullmatch(r"iPhone \d+", name) else 0
        key = (version, plain, name)
        if best is None or key > best[0]:
            best = (key, dev["udid"], name)
if best is None:
    sys.exit("利用可能な iPhone シミュレータがありません")
print(best[1])
sys.stderr.write(f"simulator: {best[2]} ({best[1]})\n")
')"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
echo "::endgroup::"

FORMAT="cat"
if command -v xcbeautify >/dev/null 2>&1; then
  FORMAT="xcbeautify --renderer github-actions"
fi

COMMON=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "id=$UDID"
  -derivedDataPath "$DERIVED"
  -skipPackagePluginValidation
  -skipMacroValidation
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGN_IDENTITY=""
  DEVELOPMENT_TEAM=""
  COMPILER_INDEX_STORE_ENABLE=NO
)

echo "::group::Build"
set -o pipefail
xcodebuild "${COMMON[@]}" build-for-testing 2>&1 | $FORMAT
echo "::endgroup::"

echo "::group::Test"
xcodebuild "${COMMON[@]}" test-without-building 2>&1 | $FORMAT
echo "::endgroup::"
