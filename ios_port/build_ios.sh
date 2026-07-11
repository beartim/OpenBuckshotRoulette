#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.openbuckshotroulette}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
UNSIGNED="${UNSIGNED:-0}"
ALLOW_INSECURE_WS="${ALLOW_INSECURE_WS:-1}"

fail() { echo "error: $*" >&2; exit 1; }
[[ "$(uname -s)" == "Darwin" ]] || fail "iOS compilation requires macOS with Xcode."
command -v xcodebuild >/dev/null || fail "xcodebuild not found; install/open Xcode first."
[[ -x "$GODOT_BIN" ]] || fail "Godot executable not found: $GODOT_BIN"
[[ "$APPLE_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "APPLE_TEAM_ID must be a 10-character Apple Team ID."
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "BUNDLE_ID contains invalid characters."

case "$EXPORT_METHOD" in
  development|ad-hoc|app-store-connect) ;;
  app-store) EXPORT_METHOD="app-store-connect" ;;
  *) fail "EXPORT_METHOD must be development, ad-hoc, or app-store-connect" ;;
esac

cd "$ROOT"
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
plist = plist.replace('\\', '\\\\').replace('"', '\\"')
out = (template
       .replace("__APPLE_TEAM_ID__", team)
       .replace("__BUNDLE_ID__", bundle)
       .replace("__ADDITIONAL_PLIST_CONTENT__", plist))
Path("export_presets.cfg").write_text(out, encoding="utf-8")
PY

rm -rf build/ios build/archive build/ipa build/DerivedData build/Payload
mkdir -p build/ios build/ipa

# Import resources first. A nonzero exit here should stop the build because missing imports
# commonly become opaque Xcode runtime failures.
"$GODOT_BIN" --headless --editor --path "$ROOT" --quit-after 2

# Godot exports an Xcode project into this folder.
"$GODOT_BIN" --headless --path "$ROOT" --export-release "iOS" "$ROOT/build/ios/OpenBuckshotRoulette"

PROJECT="$(find "$ROOT/build/ios" -name '*.xcodeproj' -print -quit)"
[[ -n "$PROJECT" ]] || fail "Godot did not produce an .xcodeproj under build/ios."
SCHEME="$(basename "$PROJECT" .xcodeproj)"

echo "Xcode project: $PROJECT"
echo "Scheme: $SCHEME"

if [[ "$UNSIGNED" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath "$ROOT/build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    build

  APP="$(find "$ROOT/build/DerivedData/Build/Products" -path '*Release-iphoneos/*.app' -print -quit)"
  [[ -n "$APP" ]] || fail "Unsigned .app not found after Xcode build."
  mkdir -p "$ROOT/build/Payload"
  ditto "$APP" "$ROOT/build/Payload/$(basename "$APP")"
  (cd "$ROOT/build" && /usr/bin/zip -qry "ipa/OpenBuckshotRoulette-unsigned.ipa" Payload)
  echo "Created unsigned IPA: $ROOT/build/ipa/OpenBuckshotRoulette-unsigned.ipa"
  echo "This file must be signed before it can be installed on a normal iOS device."
  exit 0
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "$ROOT/build/archive/OpenBuckshotRoulette.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

python3 - "$APPLE_TEAM_ID" "$EXPORT_METHOD" <<'PY'
from pathlib import Path
import sys
team, method = sys.argv[1:]
t = Path("ios_port/ExportOptions.plist.template").read_text(encoding="utf-8")
Path("build/ExportOptions.plist").write_text(
    t.replace("__APPLE_TEAM_ID__", team).replace("__EXPORT_METHOD__", method),
    encoding="utf-8",
)
PY

xcodebuild \
  -exportArchive \
  -archivePath "$ROOT/build/archive/OpenBuckshotRoulette.xcarchive" \
  -exportPath "$ROOT/build/ipa" \
  -exportOptionsPlist "$ROOT/build/ExportOptions.plist" \
  -allowProvisioningUpdates

IPA="$(find "$ROOT/build/ipa" -name '*.ipa' -print -quit)"
[[ -n "$IPA" ]] || fail "Xcode export finished but no IPA was found."
echo "Created signed IPA: $IPA"
