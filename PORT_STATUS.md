# Port status v4

- Godot import: passed in the supplied diagnostic run.
- Godot iOS Xcode project generation: passed.
- Previous blocker: malformed PBX localization path containing `ES LATAM`.
- v4 fix: generic quoting of PBX name/path values containing whitespace.
- Genuine minimum OS for Godot 4.7 official iOS templates: iOS 15.0.
- iOS 9.0: not binary-compatible with the official Godot 4.7 engine template.
- Next verification: rerun GitHub Actions and inspect `xcode-build.log` if a later compile/link issue appears.
