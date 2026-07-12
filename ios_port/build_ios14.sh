#!/usr/bin/env bash
set -Eeuo pipefail

IOS_BUILD_SCRIPT_REVISION="2026-07-12-motion-sensor-workaround-v1"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.openbuckshotroulette}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
UNSIGNED="${UNSIGNED:-1}"
ALLOW_INSECURE_WS="${ALLOW_INSECURE_WS:-1}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-14.0}"
IOS_RENDERER="${IOS_RENDERER:-metal}"
IOS_CUSTOM_TEMPLATE="${IOS_CUSTOM_TEMPLATE:-res://godot-4.7-ios14-xcode16.4-template/godot-4.7-ios14-xcode16.4.zip}"
MOLTENVK_XCFRAMEWORK="${MOLTENVK_XCFRAMEWORK:-$ROOT/ios_port/deps/MoltenVK.xcframework}"
UNSIGNED_PROJECT_TEAM_ID="${UNSIGNED_PROJECT_TEAM_ID:-ABCDE12XYZ}"
LOG_DIR="$ROOT/build/logs"
SYMBOL_DIR="$ROOT/build/symbols"

mkdir -p "$LOG_DIR" "$SYMBOL_DIR"
exec > >(tee -a "$LOG_DIR/build-ios14-${IOS_RENDERER}.log") 2>&1

fail() { echo "error: $*" >&2; exit 1; }
trap 'rc=$?; echo "error: command failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND} (exit ${rc})" >&2; exit "$rc"' ERR

[[ "$(uname -s)" == "Darwin" ]] || fail "iOS compilation requires macOS."
command -v xcodebuild >/dev/null || fail "xcodebuild is missing."
command -v xcrun >/dev/null || fail "xcrun is missing."
command -v plutil >/dev/null || fail "plutil is missing."
command -v ditto >/dev/null || fail "ditto is missing."
[[ -x "$GODOT_BIN" ]] || fail "Godot editor is missing: $GODOT_BIN"
[[ -f "$ROOT/project.godot" ]] || fail "project.godot is missing."
[[ -f "$ROOT/ios_port/apply_ios_port.py" ]] || fail "apply_ios_port.py is missing."
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || fail "Invalid bundle identifier: $BUNDLE_ID"
[[ "$IOS_DEPLOYMENT_TARGET" == "14.0" ]] || fail "This workflow is intentionally fixed to iOS 14.0."
case "$IOS_RENDERER" in vulkan|metal|opengl3) ;; *) fail "IOS_RENDERER must be vulkan, metal, or opengl3." ;; esac
[[ -f "$ROOT/ios_port/prepare_ios14_runtime.py" ]] || fail "prepare_ios14_runtime.py is missing."

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
echo "Build script revision: $IOS_BUILD_SCRIPT_REVISION"
echo "Godot: $("$GODOT_BIN" --version)"
echo "Xcode: $XCODE_VERSION"
echo "iPhoneOS SDK: $(xcrun --sdk iphoneos --show-sdk-version)"
echo "Minimum iOS: $IOS_DEPLOYMENT_TARGET"
echo "Custom template: $IOS_CUSTOM_TEMPLATE"
echo "Renderer: $IOS_RENDERER"

python3 ios_port/apply_ios_port.py --project-root "$ROOT"
python3 ios_port/prepare_ios14_runtime.py --project-root "$ROOT" --renderer "$IOS_RENDERER" --log-dir build/logs

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

rm -rf .godot build/ios build/archive build/ipa build/DerivedData build/Payload
mkdir -p build/ios/project build/ipa "$LOG_DIR" "$SYMBOL_DIR"

"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --import \
  2>&1 | tee "$LOG_DIR/godot-import.log"

# With application/export_project_only=true, Godot 4.7 normally writes the
# Xcode project directly into build/ios even when the requested path ends in
# .zip. Older/custom exporter variants may still produce a ZIP. Support both.
IOS_EXPORT_REQUEST="$ROOT/build/ios/OpenBuckshotRoulette.zip"
"$GODOT_BIN" \
  --headless \
  --verbose \
  --path "$ROOT" \
  --export-release "iOS 14 Custom" "$IOS_EXPORT_REQUEST" \
  2>&1 | tee "$LOG_DIR/godot-export.log"

{
  echo "Requested export path: $IOS_EXPORT_REQUEST"
  echo "Export directory contents:"
  find "$ROOT/build/ios" -maxdepth 5 -print | sort
} > "$LOG_DIR/ios-export-output.txt"

# Preferred/current behavior: direct project output.
PROJECT="$(find "$ROOT/build/ios" \
  -path "$ROOT/build/ios/project" -prune -o \
  -type d -name '*.xcodeproj' -print -quit 2>/dev/null || true)"

# Compatibility behavior: archive output. Extract only if no direct project
# was found, because the direct output is already complete and avoids a second
# copy of the large XCFramework.
if [[ -z "$PROJECT" && -s "$IOS_EXPORT_REQUEST" ]]; then
  rm -rf "$ROOT/build/ios/project"
  mkdir -p "$ROOT/build/ios/project"
  unzip -q "$IOS_EXPORT_REQUEST" -d "$ROOT/build/ios/project"
  PROJECT="$(find "$ROOT/build/ios/project" -type d -name '*.xcodeproj' -print -quit 2>/dev/null || true)"
fi

if [[ -z "$PROJECT" ]]; then
  cat "$LOG_DIR/ios-export-output.txt"
  fail "Godot finished exporting but no Xcode project was found in either direct or ZIP output."
fi

echo "Detected Xcode project: $PROJECT" | tee "$LOG_DIR/detected-xcode-project.txt"

# The runtime renderer can be native Metal or OpenGL, but this custom Godot
# static library was compiled with the Vulkan driver included. Registration
# objects in libgodot.a keep Vulkan references alive at link time, so MoltenVK
# is still required to satisfy the vk* symbols even when Vulkan is not selected
# at runtime. Keep the PBX reference and inject the static XCFramework.
PROJECT_PARENT="$(dirname "$PROJECT")"
MOLTENVK_DEST="$PROJECT_PARENT/MoltenVK.xcframework"

resolve_moltenvk_source() {
  local candidates=(
    "$MOLTENVK_XCFRAMEWORK"
    "$ROOT/ios_port/deps/MoltenVK.xcframework"
    "/opt/homebrew/Frameworks/MoltenVK.xcframework"
    "/usr/local/Frameworks/MoltenVK.xcframework"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" \
      && -f "$candidate/Info.plist" \
      && -f "$candidate/ios-arm64/libMoltenVK.a" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

MOLTENVK_SOURCE="$(resolve_moltenvk_source || true)"
[[ -n "$MOLTENVK_SOURCE" ]] || fail \
  "MoltenVK.xcframework is required by the custom libgodot.a. The workflow must download the static Khronos framework first."
rm -rf "$MOLTENVK_DEST"
ditto "$MOLTENVK_SOURCE" "$MOLTENVK_DEST"
[[ -f "$MOLTENVK_DEST/Info.plist" ]] || fail "MoltenVK Info.plist is missing after injection."
[[ -f "$MOLTENVK_DEST/ios-arm64/libMoltenVK.a" ]] || fail "MoltenVK iOS arm64 static library is missing after injection."
MOLTENVK_STATIC="$MOLTENVK_DEST/ios-arm64/libMoltenVK.a"
plutil -lint "$MOLTENVK_DEST/Info.plist" | tee "$LOG_DIR/moltenvk-info-plist-lint.log"

# Verify this is the real static MoltenVK archive, not an XCFramework wrapper
# without the Vulkan entry points required by libgodot.a.
xcrun nm -gU "$MOLTENVK_STATIC" > "$LOG_DIR/moltenvk-global-symbols.txt" 2>&1
if ! grep -Eq '[[:space:]]_vkCreateInstance$' "$LOG_DIR/moltenvk-global-symbols.txt"; then
  fail "The selected MoltenVK archive does not export _vkCreateInstance."
fi
if ! grep -Eq '[[:space:]]_vkGetInstanceProcAddr$' "$LOG_DIR/moltenvk-global-symbols.txt"; then
  fail "The selected MoltenVK archive does not export _vkGetInstanceProcAddr."
fi
{
  echo "Runtime renderer: $IOS_RENDERER"
  echo "MoltenVK source: $MOLTENVK_SOURCE"
  echo "MoltenVK destination: $MOLTENVK_DEST"
  du -sh "$MOLTENVK_DEST"
  find "$MOLTENVK_DEST" -maxdepth 3 -type f -print | sort
} > "$LOG_DIR/moltenvk-framework.txt"
xcrun otool -l "$MOLTENVK_DEST/ios-arm64/libMoltenVK.a" \
  > "$LOG_DIR/moltenvk-build-versions.txt" 2>&1 || true

PBXPROJ="$PROJECT/project.pbxproj"
[[ -s "$PBXPROJ" ]] || fail "Generated project.pbxproj is missing."

# Work around a Godot 4.7 Apple Embedded startup bug. GDTView polls
# CoreMotion from drawView before Input::get_singleton() is guaranteed to be
# initialized. The unguarded update_gravity()/accelerometer/etc. calls then
# dereference a null Input pointer. OpenBuckshotRoulette does not use motion
# sensors, so replace -[GDTView handleMotion] with a no-op at process startup.
#
# This workaround is injected into Godot's generated dummy.cpp, which is
# already part of the application target. It does not modify the precompiled
# libgodot.a and therefore avoids rebuilding the 100 MB custom template.
MOTION_WORKAROUND_MARKER="OPENBUCKSHOT_GODOT47_DISABLE_MOTION_V1"
DUMMY_CPP="$PROJECT_PARENT/dummy.cpp"
if [[ ! -f "$DUMMY_CPP" ]]; then
  DUMMY_CPP="$(find "$PROJECT_PARENT" -maxdepth 3 -type f -name dummy.cpp -print -quit 2>/dev/null || true)"
fi
[[ -n "$DUMMY_CPP" && -f "$DUMMY_CPP" ]] || fail "Godot generated project has no dummy.cpp for the motion workaround."
if ! grep -q 'path = dummy.cpp;' "$PBXPROJ"; then
  fail "Generated Xcode target does not reference dummy.cpp; refusing to inject an uncompiled workaround."
fi
if ! grep -Fq "$MOTION_WORKAROUND_MARKER" "$DUMMY_CPP"; then
  cat >> "$DUMMY_CPP" <<'CPP'

// OPENBUCKSHOT_GODOT47_DISABLE_MOTION_V1
// Runtime workaround for Godot 4.7 Apple Embedded startup crash:
// GDTView::handleMotion can call Input::set_gravity before the Input singleton
// exists. Objective-C classes are registered before C/C++ constructors run,
// so safely replace this optional sensor callback before UIApplicationMain.
#include <objc/objc.h>
#include <objc/runtime.h>

extern "C" {
static void openbuckshot_noop_handle_motion(id self, SEL command) {
    (void)self;
    (void)command;
}

__attribute__((constructor))
static void openbuckshot_disable_godot_motion_polling(void) {
    Class view_class = objc_getClass("GDTView");
    if (view_class == Nil) {
        return;
    }

    SEL selector = sel_registerName("handleMotion");
    Method method = class_getInstanceMethod(view_class, selector);
    if (method == nullptr) {
        return;
    }

    method_setImplementation(method, (IMP)openbuckshot_noop_handle_motion);
}
}
CPP
fi

grep -Fq "$MOTION_WORKAROUND_MARKER" "$DUMMY_CPP" || fail "Motion workaround marker was not written to dummy.cpp."
cp "$DUMMY_CPP" "$LOG_DIR/generated-dummy-with-motion-workaround.cpp"
{
  echo "revision=$MOTION_WORKAROUND_MARKER"
  echo "source=$DUMMY_CPP"
  echo "pbx_reference_count=$(grep -c 'path = dummy.cpp;' "$PBXPROJ" || true)"
  grep -n -A35 -B3 "$MOTION_WORKAROUND_MARKER" "$DUMMY_CPP"
} | tee "$LOG_DIR/motion-workaround.txt"

cp "$PBXPROJ" "$LOG_DIR/generated-project.before-fix.pbxproj"

python3 - "$PBXPROJ" "$IOS_DEPLOYMENT_TARGET" "$LOG_DIR/pbxproj-fixes.log" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
min_ios = sys.argv[2]
log_path = Path(sys.argv[3])
text = path.read_text(encoding="utf-8")
changes: list[str] = []

# Quote unquoted PBX name/path values containing spaces, such as ES LATAM.
assignment = re.compile(r'\b(name|path) = ([^";\n][^;\n]*\s+[^;\n]*);')

def quote_value(match: re.Match[str]) -> str:
    key = match.group(1)
    value = match.group(2).strip()
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    changes.append(f"quoted {key}: {value!r}")
    return f'{key} = "{escaped}";'

text = assignment.sub(quote_value, text)
text, deployment_count = re.subn(
    r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*[^;]+;",
    f"IPHONEOS_DEPLOYMENT_TARGET = {min_ios};",
    text,
)
changes.append(
    f"set IPHONEOS_DEPLOYMENT_TARGET={min_ios} in "
    f"{deployment_count} build settings"
)

# Do not rely on generated PBX references for MoltenVK. Custom exporters and
# previous compatibility patches may add, remove, or partially rewrite those
# records. Remove them consistently and link the static archive explicitly via
# OTHER_LDFLAGS with -force_load below.
lines = text.splitlines(keepends=True)
kept_lines = []
removed_moltenvk = []
for line in lines:
    if "MoltenVK.xcframework" in line or "/* MoltenVK */" in line or "name = MoltenVK;" in line:
        removed_moltenvk.append(line.rstrip("\n"))
    else:
        kept_lines.append(line)
text = "".join(kept_lines)
changes.append(f"removed {len(removed_moltenvk)} generated MoltenVK PBX lines")
for line in removed_moltenvk:
    changes.append(f"removed PBX line: {line.strip()}")
changes.append("MoltenVK will be linked explicitly with -force_load")

path.write_text(text, encoding="utf-8")
log_path.write_text("\n".join(changes) + "\n", encoding="utf-8")
PY

cp "$PBXPROJ" "$LOG_DIR/generated-project.pbxproj"
nl -ba "$PBXPROJ" | sed -n '35,95p' > "$LOG_DIR/generated-project-lines-35-95.txt"
cat "$LOG_DIR/pbxproj-fixes.log"
plutil -lint "$PBXPROJ" | tee "$LOG_DIR/pbxproj-lint.log"
# In force-load mode the PBX project must NOT contain a MoltenVK framework
# reference. The archive is linked explicitly through OTHER_LDFLAGS below.
if grep -q 'MoltenVK.xcframework' "$PBXPROJ"; then
  fail "Stale MoltenVK PBX references remain after cleanup; explicit force-load could link it twice."
fi
[[ -f "$MOLTENVK_STATIC" ]] || fail "MoltenVK static archive disappeared before Xcode build: $MOLTENVK_STATIC"
[[ -s "$MOLTENVK_STATIC" ]] || fail "MoltenVK static archive is empty: $MOLTENVK_STATIC"
echo "PBX MoltenVK references: 0 (expected for force-load mode)" | tee "$LOG_DIR/moltenvk-pbx-mode.txt"

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
data["UIFileSharingEnabled"] = True
data["LSSupportsOpeningDocumentsInPlace"] = True
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

# The generated PBX project has historically alternated between missing,
# stale, and removed MoltenVK references. Link the static archive explicitly.
# -force_load is intentional: libgodot.a introduces Vulkan references late in
# the final link, so a normal archive argument can be skipped due to link order.
MOLTENVK_LINK_FLAGS="\$(inherited) -Wl,-force_load,$MOLTENVK_STATIC -framework Metal -framework Foundation -framework QuartzCore -framework CoreGraphics -framework IOSurface -framework UIKit"
{
  echo "MoltenVK static archive: $MOLTENVK_STATIC"
  echo "OTHER_LDFLAGS: $MOLTENVK_LINK_FLAGS"
} | tee "$LOG_DIR/moltenvk-link-flags.txt"

COMMON_XCODE_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration Release
  -sdk iphoneos
  -destination 'generic/platform=iOS'
  -derivedDataPath "$ROOT/build/DerivedData"
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
  GCC_GENERATE_DEBUGGING_SYMBOLS=YES
  COPY_PHASE_STRIP=NO
  STRIP_INSTALLED_PRODUCT=NO
  LD_GENERATE_MAP_FILE=YES
  LD_MAP_FILE_PATH="$SYMBOL_DIR/OpenBuckshotRoulette-${IOS_RENDERER}.linkmap"
  DEAD_CODE_STRIPPING=YES
  CLANG_ENABLE_MODULES=YES
  CLANG_MODULES_AUTOLINK=YES
  OTHER_LDFLAGS="$MOLTENVK_LINK_FLAGS"
)

xcodebuild \
  "${COMMON_XCODE_ARGS[@]}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  -showBuildSettings \
  > "$LOG_DIR/xcode-build-settings.txt" 2>&1
if ! grep -Fq -- "-force_load,$MOLTENVK_STATIC" "$LOG_DIR/xcode-build-settings.txt"; then
  cat "$LOG_DIR/xcode-build-settings.txt"
  fail "Xcode did not accept the explicit MoltenVK -force_load setting."
fi

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

dwarfdump --uuid "$APP/$EXECUTABLE" | tee "$SYMBOL_DIR/app-binary-uuid.txt"
DSYM="$(find "$ROOT/build/DerivedData" -type d -name '*.app.dSYM' -print -quit 2>/dev/null || true)"
if [[ -n "$DSYM" ]]; then
  ditto "$DSYM" "$SYMBOL_DIR/$(basename "$DSYM")"
  dwarfdump --uuid "$DSYM" | tee "$SYMBOL_DIR/dsym-uuid.txt"
else
  echo "warning: no dSYM found" | tee "$SYMBOL_DIR/dsym-missing.txt"
fi

mkdir -p "$ROOT/build/Payload"
ditto "$APP" "$ROOT/build/Payload/$(basename "$APP")"
(
  cd "$ROOT/build"
  /usr/bin/zip -qry "ipa/OpenBuckshotRoulette-iOS14-${IOS_RENDERER}-unsigned.ipa" Payload
)
[[ -s "$ROOT/build/ipa/OpenBuckshotRoulette-iOS14-${IOS_RENDERER}-unsigned.ipa" ]] || fail "IPA packaging failed."
shasum -a 256 "$ROOT/build/ipa/OpenBuckshotRoulette-iOS14-${IOS_RENDERER}-unsigned.ipa" \
  | tee "$LOG_DIR/ipa.sha256"
echo "Created: $ROOT/build/ipa/OpenBuckshotRoulette-iOS14-${IOS_RENDERER}-unsigned.ipa"
