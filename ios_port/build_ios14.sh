#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.openbuckshotroulette}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
UNSIGNED="${UNSIGNED:-1}"
ALLOW_INSECURE_WS="${ALLOW_INSECURE_WS:-1}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-14.0}"
IOS_CUSTOM_TEMPLATE="${IOS_CUSTOM_TEMPLATE:-res://godot-4.7-ios14-xcode16.4-template/godot-4.7-ios14-xcode16.4.zip}"
UNSIGNED_PROJECT_TEAM_ID="${UNSIGNED_PROJECT_TEAM_ID:-ABCDE12XYZ}"
LOG_DIR="$ROOT/build/logs"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/build-ios14.log") 2>&1

fail() { echo "error: $*" >&2; exit 1; }
trap 'rc=$?; echo "error: command failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND} (exit ${rc})" >&2; exit "$rc"' ERR

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS compilation requires macOS."
command -v xcodebuild >/dev/null || fail "xcodebuild is missing."
command -v xcrun >/dev/null || fail "xcrun is missing."
command -v plutil >/dev/null || fail "plutil is missing."
[[ -x "$GODOT_BIN" ]] || fail "Godot editor is missing: $GODOT_BIN"
[[ -f "$ROOT/project.godot" ]] || fail "project.godot is missing."
[[ -f "$ROOT/ios_port/apply_ios_port.py" ]] || fail "apply_ios_port.py is missing."
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "Invalid bundle identifier: $BUNDLE_ID"
[[ "$IOS_DEPLOYMENT_TARGET" == "14.0" ]] || fail "This workflow is intentionally fixed to iOS 14.0."

CUSTOM_TEMPLATE_FILE=""
case "$IOS_CUSTOM_TEMPLATE" in
  res://*) CUSTOM_TEMPLATE_FILE="$ROOT/${IOS_CUSTOM_TEMPLATE#res://}" ;;
  /*) CUSTOM_TEMPLATE_FILE="$IOS_CUSTOM_TEMPLATE" ;;
  *) CUSTOM_TEMPLATE_FILE="$ROOT/$IOS_CUSTOM_TEMPLATE" ;;
esac
[[ -s "$CUSTOM_TEMPLATE_FILE" ]] || fail "Custom iOS 14 template is missing: $CUSTOM_TEMPLATE_FILE"
unzip -t "$CUSTOM_TEMPLATE_FILE" > "$LOG_DIR/custom-template-recheck.txt"

XCODE_OUTPUT="$(xcodebuild -version 2>&1)"
printf '%s\n' "$XCODE_OUTPUT" | tee "$LOG_DIR/xcode-version-from-build.txt"
XCODE_VERSION="$(sed -nE 's/^Xcode[[:space:]]+([^[:space:]]+).*/\1/p' <<< "$XCODE_OUTPUT")"
[[ "$XCODE_VERSION" == 16.4* ]] || fail "The custom template was built with Xcode 16.4; selected Xcode is ${XCODE_VERSION:-unknown}."

case "$EXPORT_METHOD" in
  development|ad-hoc|app-store-connect) ;;
  app-store) EXPORT_METHOD="app-store-connect" ;;
  *) fail "Unsupported EXPORT_METHOD: $EXPORT_METHOD" ;;
esac

if [[ "$UNSIGNED" == "1" ]]; then
  PROJECT_TEAM_ID="$UNSIGNED_PROJECT_TEAM_ID"
  DEBUG_SIGN_IDENTITY=""
  RELEASE_SIGN_IDENTITY=""
else
  [[ "$APPLE_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "A valid Apple Team ID is required for signed builds."
  PROJECT_TEAM_ID="$APPLE_TEAM_ID"
  DEBUG_SIGN_IDENTITY="Apple Development"
  RELEASE_SIGN_IDENTITY="Apple Distribution"
fi
[[ "$PROJECT_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]] || fail "The project Team ID must be 10 alphanumeric characters."

cd "$ROOT"
echo "Godot: $("$GODOT_BIN" --version)"
echo "Xcode: $XCODE_VERSION"
echo "iPhoneOS SDK: $(xcrun --sdk iphoneos --show-sdk-version)"
echo "Minimum iOS: $IOS_DEPLOYMENT_TARGET"
echo "Custom template: $IOS_CUSTOM_TEMPLATE"

python3 ios_port/apply_ios_port.py --project-root "$ROOT"

python3 - \
  "$PROJECT_TEAM_ID" \
  "$BUNDLE_ID" \
  "$DEBUG_SIGN_IDENTITY" \
  "$RELEASE_SIGN_IDENTITY" \
  "$IOS_DEPLOYMENT_TARGET" \
  "$IOS_CUSTOM_TEMPLATE" <<'PY'
from pathlib import Path
import sys

team, bundle, debug_identity, release_identity, min_ios, custom_template = sys.argv[1:]
template = Path("ios_port/export_presets.ios14.cfg.template").read_text(encoding="utf-8")
out = (
    template.replace("__PROJECT_TEAM_ID__", team)
    .replace("__BUNDLE_ID__", bundle)
    .replace("__DEBUG_SIGN_IDENTITY__", debug_identity)
    .replace("__RELEASE_SIGN_IDENTITY__", release_identity)
    .replace("__IOS_DEPLOYMENT_TARGET__", min_ios)
    .replace("__CUSTOM_TEMPLATE__", custom_template)
)
Path("export_presets.cfg").write_text(out, encoding="utf-8")
PY
cp export_presets.cfg "$LOG_DIR/export_presets.generated.cfg"

rm -rf build/ios build/archive build/ipa build/DerivedData build/Payload
mkdir -p build/ios/project build/ipa "$LOG_DIR"

"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --import \
  2>&1 | tee "$LOG_DIR/godot-import.log"

IOS_EXPORT_ZIP="$ROOT/build/ios/OpenBuckshotRoulette.zip"
"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --export-release "iOS 14 Custom" "$IOS_EXPORT_ZIP" \
  2>&1 | tee "$LOG_DIR/godot-export.log"

[[ -s "$IOS_EXPORT_ZIP" ]] || fail "Godot did not create the iOS Xcode-project ZIP."
unzip -q "$IOS_EXPORT_ZIP" -d "$ROOT/build/ios/project"

PROJECT="$(find "$ROOT/build/ios/project" -name '*.xcodeproj' -print -quit)"
[[ -n "$PROJECT" ]] || fail "No Xcode project was generated."
PBXPROJ="$PROJECT/project.pbxproj"
[[ -s "$PBXPROJ" ]] || fail "Generated project.pbxproj is missing."
cp "$PBXPROJ" "$LOG_DIR/generated-project.before-fix.pbxproj"

python3 - "$PBXPROJ" "$IOS_DEPLOYMENT_TARGET" "$LOG_DIR/pbxproj-fixes.log" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
min_ios = sys.argv[2]
log_path = Path(sys.argv[3])
text = path.read_text(encoding="utf-8")
changes = []

assignment = re.compile(r'\b(name|path) = ([^";\n][^;\n]*\s+[^;\n]*);')

def quote_value(match: re.Match[str]) -> str:
    key = match.group(1)
    value = match.group(2).strip()
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    changes.append(f"quoted {key}: {value!r}")
    return f'{key} = "{escaped}";'

text = assignment.sub(quote_value, text)
text, count = re.subn(
    r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*[^;]+;",
    f"IPHONEOS_DEPLOYMENT_TARGET = {min_ios};",
    text,
)
changes.append(f"set IPHONEOS_DEPLOYMENT_TARGET={min_ios} in {count} build settings")
path.write_text(text, encoding="utf-8")
log_path.write_text("\n".join(changes) + "\n", encoding="utf-8")
PY

cp "$PBXPROJ" "$LOG_DIR/generated-project.pbxproj"
nl -ba "$PBXPROJ" | sed -n '35,95p' > "$LOG_DIR/generated-project-lines-35-95.txt"
cat "$LOG_DIR/pbxproj-fixes.log"
plutil -lint "$PBXPROJ" | tee "$LOG_DIR/pbxproj-lint.log"

INFO_PLIST="$(find "$(dirname "$PROJECT")" -type f -name '*-Info.plist' -print -quit)"
[[ -n "$INFO_PLIST" ]] || fail "Generated Info.plist was not found."
python3 - "$INFO_PLIST" "$ALLOW_INSECURE_WS" "$IOS_DEPLOYMENT_TARGET" <<'PY'
from pathlib import Path
import plistlib
import sys

path = Path(sys.argv[1])
allow_insecure_ws = sys.argv[2] == "1"
min_ios = sys.argv[3]
with path.open("rb") as handle:
    data = plistlib.load(handle)
data["MinimumOSVersion"] = min_ios
if allow_insecure_ws:
    ats = data.setdefault("NSAppTransportSecurity", {})
    domains = ats.setdefault("NSExceptionDomains", {})
    entry = domains.setdefault("buckds.1503dev.top", {})
    entry["NSIncludesSubdomains"] = True
    entry["NSTemporaryExceptionAllowsInsecureHTTPLoads"] = True
with path.open("wb") as handle:
    plistlib.dump(data, handle, fmt=plistlib.FMT_XML, sort_keys=False)
PY
cp "$INFO_PLIST" "$LOG_DIR/generated-app-Info.plist"
plutil -lint "$INFO_PLIST" | tee "$LOG_DIR/info-plist-lint.log"

xcodebuild -project "$PROJECT" -list -json \
  > "$LOG_DIR/xcode-project-list.json" \
  2> "$LOG_DIR/xcode-project-list.stderr.log"
SCHEME="$(python3 - "$LOG_DIR/xcode-project-list.json" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
print((data.get("project", {}).get("schemes") or [""])[0])
PY
)"
[[ -n "$SCHEME" ]] || SCHEME="$(basename "$PROJECT" .xcodeproj)"

echo "Xcode project: $PROJECT"
echo "Scheme: $SCHEME"

COMMON_XCODE_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration Release
  -sdk iphoneos
  -destination 'generic/platform=iOS'
  -derivedDataPath "$ROOT/build/DerivedData"
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"
)

if [[ "$UNSIGNED" == "1" ]]; then
  xcodebuild \
    "${COMMON_XCODE_ARGS[@]}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY= \
    DEVELOPMENT_TEAM= \
    PROVISIONING_PROFILE= \
    PROVISIONING_PROFILE_SPECIFIER= \
    build \
    2>&1 | tee "$LOG_DIR/xcode-build.log"
else
  fail "Signed archive mode is not enabled in this iOS 14 CI script yet."
fi

APP="$(find "$ROOT/build/DerivedData/Build/Products" -path '*Release-iphoneos/*.app' -print -quit)"
[[ -n "$APP" ]] || fail "Unsigned .app was not produced."
APP_PLIST="$APP/Info.plist"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PLIST")"
MINIMUM_OS="$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$APP_PLIST")"
echo "$MINIMUM_OS" | tee "$LOG_DIR/final-minimum-os-version.txt"
[[ "$MINIMUM_OS" == "14.0" ]] || fail "Final Info.plist minimum is $MINIMUM_OS instead of 14.0."

xcrun vtool -show-build "$APP/$EXECUTABLE" \
  > "$LOG_DIR/final-mach-o-build-version.txt" 2>&1
cat "$LOG_DIR/final-mach-o-build-version.txt"
if ! grep -Eq 'minos[[:space:]]+14\.0' "$LOG_DIR/final-mach-o-build-version.txt"; then
  fail "Final executable does not report Mach-O minos 14.0."
fi

mkdir -p "$ROOT/build/Payload"
ditto "$APP" "$ROOT/build/Payload/$(basename "$APP")"
(
  cd "$ROOT/build"
  /usr/bin/zip -qry "ipa/OpenBuckshotRoulette-iOS14-unsigned.ipa" Payload
)
[[ -s "$ROOT/build/ipa/OpenBuckshotRoulette-iOS14-unsigned.ipa" ]] || fail "IPA packaging failed."
shasum -a 256 "$ROOT/build/ipa/OpenBuckshotRoulette-iOS14-unsigned.ipa" \
  | tee "$LOG_DIR/ipa.sha256"
echo "Created: $ROOT/build/ipa/OpenBuckshotRoulette-iOS14-unsigned.ipa"
