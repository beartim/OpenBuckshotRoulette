#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.openbuckshotroulette}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
UNSIGNED="${UNSIGNED:-0}"
ALLOW_INSECURE_WS="${ALLOW_INSECURE_WS:-1}"
LOG_DIR="$ROOT/build/logs"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/build-ios.log") 2>&1

fail() { echo "error: $*" >&2; exit 1; }
trap 'rc=$?; echo "error: command failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND} (exit ${rc})" >&2; exit "$rc"' ERR

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS compilation requires macOS with Xcode."
command -v xcodebuild >/dev/null || fail "xcodebuild not found; install/open Xcode first."
command -v xcrun >/dev/null || fail "xcrun not found; install the Xcode command line tools."
[[ -x "$GODOT_BIN" ]] || fail "Godot executable not found: $GODOT_BIN"
[[ "$APPLE_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "APPLE_TEAM_ID must be a 10-character Apple Team ID."
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "BUNDLE_ID contains invalid characters."
[[ -f "$ROOT/project.godot" ]] || fail "project.godot is missing. Run this kit from a full OpenBuckshotRoulette repository."

case "$EXPORT_METHOD" in
  development|ad-hoc|app-store-connect) ;;
  app-store) EXPORT_METHOD="app-store-connect" ;;
  *) fail "EXPORT_METHOD must be development, ad-hoc, or app-store-connect" ;;
esac

cd "$ROOT"
echo "Godot: $("$GODOT_BIN" --version)"
echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "iPhoneOS SDK: $(xcrun --sdk iphoneos --show-sdk-version)"

python3 ios_port/apply_ios_port.py --project-root "$ROOT"

ATS_XML=""
if [[ "$ALLOW_INSECURE_WS" == "1" ]]; then
  ATS_XML='<key>NSAppTransportSecurity</key><dict><key>NSExceptionDomains</key><dict><key>buckds.1503dev.top</key><dict><key>NSIncludesSubdomains</key><true/><key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key><true/></dict></dict></dict>'
fi

python3 - "$APPLE_TEAM_ID" "$BUNDLE_ID" "$ATS_XML" <<'PY'
from pathlib import Path
import sys

team, bundle, plist = sys.argv[1:]
template = Path("ios_port/export_presets.cfg.template").read_text(encoding="utf-8")
# Godot stores this field inside a quoted string.
plist = plist.replace("\\", "\\\\").replace('"', '\\"')
out = (
    template.replace("__APPLE_TEAM_ID__", team)
    .replace("__BUNDLE_ID__", bundle)
    .replace("__ADDITIONAL_PLIST_CONTENT__", plist)
)
Path("export_presets.cfg").write_text(out, encoding="utf-8")
PY

rm -rf build/ios build/archive build/ipa build/DerivedData build/Payload
mkdir -p build/ios/project build/ipa build/logs

# Godot's dedicated import mode waits until resource importing is complete.
# This replaces the old --quit-after 2 workaround, which could stop too early.
"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --import \
  2>&1 | tee "$LOG_DIR/godot-import.log"

# Godot's command-line export documentation specifies .zip for iOS output.
# The archive contains the generated Xcode project.
IOS_EXPORT_ZIP="$ROOT/build/ios/OpenBuckshotRoulette.zip"
"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --export-release "iOS" "$IOS_EXPORT_ZIP" \
  2>&1 | tee "$LOG_DIR/godot-export.log"

[[ -s "$IOS_EXPORT_ZIP" ]] || fail "Godot did not create the iOS Xcode-project ZIP: $IOS_EXPORT_ZIP"
unzip -q "$IOS_EXPORT_ZIP" -d "$ROOT/build/ios/project"

PROJECT="$(find "$ROOT/build/ios/project" -name '*.xcodeproj' -print -quit)"
[[ -n "$PROJECT" ]] || fail "Godot did not produce an .xcodeproj inside the iOS export ZIP."

xcodebuild -project "$PROJECT" -list -json > "$LOG_DIR/xcode-project-list.json"
SCHEME="$(python3 - "$LOG_DIR/xcode-project-list.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
project = data.get("project", {})
schemes = project.get("schemes", [])
print(schemes[0] if schemes else "")
PY
)"
[[ -n "$SCHEME" ]] || SCHEME="$(basename "$PROJECT" .xcodeproj)"

echo "Xcode project: $PROJECT"
echo "Scheme: $SCHEME"

if [[ "$UNSIGNED" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$ROOT/build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY= \
    DEVELOPMENT_TEAM= \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    build \
    2>&1 | tee "$LOG_DIR/xcode-build.log"

  APP="$(find "$ROOT/build/DerivedData/Build/Products" -path '*Release-iphoneos/*.app' -print -quit)"
  [[ -n "$APP" ]] || fail "Unsigned .app not found after Xcode build."
  mkdir -p "$ROOT/build/Payload"
  ditto "$APP" "$ROOT/build/Payload/$(basename "$APP")"
  (cd "$ROOT/build" && /usr/bin/zip -qry "ipa/OpenBuckshotRoulette-unsigned.ipa" Payload)
  [[ -s "$ROOT/build/ipa/OpenBuckshotRoulette-unsigned.ipa" ]] || fail "IPA packaging failed."
  echo "Created unsigned IPA: $ROOT/build/ipa/OpenBuckshotRoulette-unsigned.ipa"
  echo "This file must be signed before it can be installed on a normal iOS device."
  exit 0
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$ROOT/build/archive/OpenBuckshotRoulette.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive \
  2>&1 | tee "$LOG_DIR/xcode-archive.log"

python3 - "$APPLE_TEAM_ID" "$EXPORT_METHOD" <<'PY'
from pathlib import Path
import sys

team, method = sys.argv[1:]
template = Path("ios_port/ExportOptions.plist.template").read_text(encoding="utf-8")
Path("build/ExportOptions.plist").write_text(
    template.replace("__APPLE_TEAM_ID__", team).replace("__EXPORT_METHOD__", method),
    encoding="utf-8",
)
PY

xcodebuild \
  -exportArchive \
  -archivePath "$ROOT/build/archive/OpenBuckshotRoulette.xcarchive" \
  -exportPath "$ROOT/build/ipa" \
  -exportOptionsPlist "$ROOT/build/ExportOptions.plist" \
  -allowProvisioningUpdates \
  2>&1 | tee "$LOG_DIR/xcode-export.log"

IPA="$(find "$ROOT/build/ipa" -name '*.ipa' -print -quit)"
[[ -n "$IPA" ]] || fail "Xcode export finished but no IPA was found."
echo "Created signed IPA: $IPA"
