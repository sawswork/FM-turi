#!/usr/bin/env bash
# UI テストでスクリーンショットを撮り build/screenshots に PNG を書き出す（ci-ios.sh の後に実行）。
# ci-ios.sh が起動したシミュレータ（PREFER_PRO_MAX=1 なら Pro Max）をそのまま使う。
set -euo pipefail
export PATH="/tmp/xcodegen/xcodegen/bin:$PATH"
UDID="$(xcrun simctl list devices booted -j | python3 -c '
import json, sys
for devs in json.load(sys.stdin)["devices"].values():
    for d in devs:
        if d.get("state") == "Booted" and d["name"].startswith("iPhone"):
            print(d["udid"]); sys.stderr.write("screenshots: " + d["name"] + "\n"); sys.exit(0)
sys.exit("booted iPhone simulator not found")')"
xcrun simctl status_bar "$UDID" override --time "14:30" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
rm -rf build/screenshots.xcresult build/screenshots
FORMAT="cat"
if command -v xcbeautify >/dev/null 2>&1; then
  FORMAT="xcbeautify --renderer github-actions"
fi
set -o pipefail
echo "::group::UI test"
xcodebuild -project Tide.xcodeproj -scheme TideScreenshots -destination "id=$UDID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/screenshots.xcresult \
  -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 300 -maximum-test-execution-time-allowance 600 \
  test 2>&1 | $FORMAT || echo "UI テストが失敗（スクリーンショットは撮れた分だけ出力）"
echo "::endgroup::"
mkdir -p build/screenshots
xcrun xcresulttool export attachments --path build/screenshots.xcresult --output-path build/screenshots || true
ls -la build/screenshots || true
