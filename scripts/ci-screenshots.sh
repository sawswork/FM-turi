#!/usr/bin/env bash
# UI テストでスクリーンショットを撮り build/screenshots に PNG を書き出す（ci-ios.sh の後に実行）。
set -euo pipefail
export PATH="/tmp/xcodegen/xcodegen/bin:$PATH"
# App Store の 6.9 インチ用に Pro Max を優先（無ければ起動中の iPhone）
UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
best = None
for runtime, devs in json.load(sys.stdin)["devices"].items():
    if "iOS" not in runtime:
        continue
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    version = (int(m.group(1)), int(m.group(2))) if m else (0, 0)
    for d in devs:
        name = d.get("name", "")
        if not d.get("isAvailable") or not name.startswith("iPhone"):
            continue
        key = (1 if "Pro Max" in name else 0, version, name)
        if best is None or key > best[0]:
            best = (key, d["udid"], name)
print(best[1]); sys.stderr.write("screenshots: " + best[2] + "\n")')"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl status_bar "$UDID" override --time "14:30" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
rm -rf build/screenshots.xcresult build/screenshots
set -o pipefail
xcodebuild -project Tide.xcodeproj -scheme TideScreenshots -destination "id=$UDID" \
  -derivedDataPath build/DerivedData -resultBundlePath build/screenshots.xcresult \
  -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" test 2>&1 | tail -40 || true
mkdir -p build/screenshots
xcrun xcresulttool export attachments --path build/screenshots.xcresult --output-path build/screenshots || true
ls -la build/screenshots || true
