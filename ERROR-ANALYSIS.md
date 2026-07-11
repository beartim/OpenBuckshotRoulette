# Error analysis: force-load v1 guard contradiction

The supplied run did use the new force-load script:

```text
Build script revision: 2026-07-12-moltenvk-force-load-v1
```

Godot exported the Xcode project successfully. The script then intentionally
removed four generated `MoltenVK.xcframework` PBX lines because v1 was designed
to link `libMoltenVK.a` explicitly with `OTHER_LDFLAGS=-Wl,-force_load,...`.

Immediately afterward, an obsolete guard did the opposite check:

```bash
if ! grep -q 'MoltenVK.xcframework' "$PBXPROJ"; then
    fail "Generated project has no MoltenVK reference..."
fi
```

That made the script fail before `xcodebuild -showBuildSettings` and before the
actual Xcode build. No linker was invoked in this run.

## v2 fix

- PBX MoltenVK references are expected to be absent in force-load mode.
- The script now fails only if stale PBX references remain, because that could
  link MoltenVK twice.
- It verifies that `libMoltenVK.a` exists and is non-empty.
- It still verifies the effective Xcode `OTHER_LDFLAGS` contains the exact
  `-force_load,<absolute archive path>` before compiling.
