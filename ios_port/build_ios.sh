#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.openbuckshotroulette}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
UNSIGNED="${UNSIGNED:-0}"
ALLOW_INSECURE_WS="${ALLOW_INSECURE_WS:-1}"
# Godot requires a syntactically valid 10-character Team ID even when it is
# only generating an unsigned Xcode project. This value is never used to sign.
UNSIGNED_PROJECT_TEAM_ID="${UNSIGNED_PROJECT_TEAM_ID:-ABCDE12XYZ}"
LOG_DIR="$ROOT/build/logs"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/build-ios.log") 2>&1

fail() { echo "error: $*" >&2; exit 1; }
trap 'rc=$?; echo "error: command failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND} (exit ${rc})" >&2; exit "$rc"' ERR

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS compilation requires macOS with Xcode."
command -v xcodebuild >/dev/null || fail "xcodebuild not found; install/open Xcode first."
command -v xcrun >/dev/null || fail "xcrun not found; install the Xcode command line tools."
command -v plutil >/dev/null || fail "plutil not found."
[[ -x "$GODOT_BIN" ]] || fail "Godot executable not found: $GODOT_BIN"
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "BUNDLE_ID contains invalid characters."
[[ -f "$ROOT/project.godot" ]] || fail "project.godot is missing. Run this kit from a full OpenBuckshotRoulette repository."

case "$EXPORT_METHOD" in
  development|ad-hoc|app-store-connect) ;;
  app-store) EXPORT_METHOD="app-store-connect" ;;
  *) fail "EXPORT_METHOD must be development, ad-hoc, or app-store-connect" ;;
esac

if [[ "$UNSIGNED" == "1" ]]; then
  PROJECT_TEAM_ID="$UNSIGNED_PROJECT_TEAM_ID"
  DEBUG_SIGN_IDENTITY=""
  RELEASE_SIGN_IDENTITY=""
else
  [[ "$APPLE_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "APPLE_TEAM_ID must be a valid 10-character Apple Team ID for signed builds."
  PROJECT_TEAM_ID="$APPLE_TEAM_ID"
  DEBUG_SIGN_IDENTITY="Apple Development"
  RELEASE_SIGN_IDENTITY="Apple Distribution"
fi
[[ "$PROJECT_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "The project Team ID must contain exactly 10 alphanumeric characters."

cd "$ROOT"
echo "Godot: $("$GODOT_BIN" --version)"
echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "iPhoneOS SDK: $(xcrun --sdk iphoneos --show-sdk-version)"
echo "Build mode: $([[ "$UNSIGNED" == "1" ]] && echo unsigned || echo signed)"
echo "Godot project Team ID: $PROJECT_TEAM_ID"

python3 ios_port/apply_ios_port.py --project-root "$ROOT"

python3 - "$PROJECT_TEAM_ID" "$BUNDLE_ID" "$DEBUG_SIGN_IDENTITY" "$RELEASE_SIGN_IDENTITY" <<'PY'
from pathlib import Path
import sys

team, bundle, debug_identity, release_identity = sys.argv[1:]
template = Path("ios_port/export_presets.cfg.template").read_text(encoding="utf-8")
out = (
    template.replace("__PROJECT_TEAM_ID__", team)
    .replace("__BUNDLE_ID__", bundle)
    .replace("__DEBUG_SIGN_IDENTITY__", debug_identity)
    .replace("__RELEASE_SIGN_IDENTITY__", release_identity)
)
Path("export_presets.cfg").write_text(out, encoding="utf-8")
PY
cp export_presets.cfg "$LOG_DIR/export_presets.generated.cfg"

rm -rf build/ios build/archive build/ipa build/DerivedData build/Payload
mkdir -p build/ios/project build/ipa

"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --import \
  2>&1 | tee "$LOG_DIR/godot-import.log"

# application/export_project_only=true is essential here: Godot generates the
# Xcode project, while signing/building is performed explicitly below.
IOS_EXPORT_ZIP="$ROOT/build/ios/OpenBuckshotRoulette.zip"
"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --export-release "iOS" "$IOS_EXPORT_ZIP" \
  2>&1 | tee "$LOG_DIR/godot-export.log"

if [[ -s "$IOS_EXPORT_ZIP" ]]; then
  unzip -q "$IOS_EXPORT_ZIP" -d "$ROOT/build/ios/project"
fi

PROJECT="$(find "$ROOT/build/ios/project" "$ROOT/build/ios" -name '*.xcodeproj' -print -quit 2>/dev/null || true)"
[[ -n "$PROJECT" ]] || fail "Godot did not produce an .xcodeproj. Check godot-export.log."
PBXPROJ="$PROJECT/project.pbxproj"
[[ -s "$PBXPROJ" ]] || fail "Generated project.pbxproj is missing or empty: $PBXPROJ"

cp "$PBXPROJ" "$LOG_DIR/generated-project.pbxproj"
nl -ba "$PBXPROJ" | sed -n '35,85p' > "$LOG_DIR/generated-project-lines-35-85.txt"

if ! plutil -lint "$PBXPROJ" > "$LOG_DIR/pbxproj-lint.log" 2>&1; then
  cat "$LOG_DIR/pbxproj-lint.log"
  fail "Godot generated a malformed Xcode project. The exact project file and lines 35-85 were saved in the diagnostic artifact."
fi

# Add the temporary ATS exception after project generation instead of embedding
# XML inside export_presets.cfg. plistlib keeps the resulting Info.plist valid.
INFO_PLIST="$(find "$(dirname "$PROJECT")" -type f -name '*-Info.plist' -print -quit 2>/dev/null || true)"
[[ -n "$INFO_PLIST" ]] || fail "Generated application Info.plist was not found."
if [[ "$ALLOW_INSECURE_WS" == "1" ]]; then
  python3 - "$INFO_PLIST" <<'PY'
from pathlib import Path
import plistlib
import sys

path = Path(sys.argv[1])
with path.open("rb") as handle:
    data = plistlib.load(handle)
ats = data.setdefault("NSAppTransportSecurity", {})
domains = ats.setdefault("NSExceptionDomains", {})
entry = domains.setdefault("buckds.1503dev.top", {})
entry["NSIncludesSubdomains"] = True
entry["NSTemporaryExceptionAllowsInsecureHTTPLoads"] = True
with path.open("wb") as handle:
    plistlib.dump(data, handle, fmt=plistlib.FMT_XML, sort_keys=False)
PY
fi
cp "$INFO_PLIST" "$LOG_DIR/generated-app-Info.plist"
plutil -lint "$INFO_PLIST" | tee "$LOG_DIR/info-plist-lint.log"

if ! xcodebuild -project "$PROJECT" -list -json > "$LOG_DIR/xcode-project-list.json" 2> "$LOG_DIR/xcode-project-list.stderr.log"; then
  cat "$LOG_DIR/xcode-project-list.stderr.log"
  fail "xcodebuild could not read the generated project."
fi
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
echo "Info.plist: $INFO_PLIST"

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
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY= \
    DEVELOPMENT_TEAM= \
    PROVISIONING_PROFILE= \
    PROVISIONING_PROFILE_SPECIFIER= \
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
  echo "The IPA must be signed before installation on a normal iOS device."
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
