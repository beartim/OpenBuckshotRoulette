# Build log analysis

The Godot export did not fail. The log reached `[ DONE ] export` and created:

- `build/ios/OpenBuckshotRoulette.xcodeproj/project.pbxproj`
- `build/ios/OpenBuckshotRoulette/`
- `build/ios/OpenBuckshotRoulette.xcframework/ios-arm64/libgodot.a`

The shell script then checked only for `build/ios/OpenBuckshotRoulette.zip` and
reported a false failure. This happens because `application/export_project_only`
exports an Xcode project rather than building an IPA, and this Godot/custom
exporter combination writes the project directly to the target directory.

The repaired script detects direct `.xcodeproj` output first, falls back to ZIP
extraction when present, and saves a complete export directory listing in
`build/logs/ios-export-output.txt`.
