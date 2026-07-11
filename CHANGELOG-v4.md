# v4 changes

- Fixed the actual Xcode project parse failure caused by the localization name `ES LATAM`.
- Added a generic PBX sanitizer that quotes any unquoted `name` or `path` value containing whitespace.
- Applies and verifies `IPHONEOS_DEPLOYMENT_TARGET` in the Godot preset and generated Xcode project.
- Writes `MinimumOSVersion` to the generated Info.plist and records the final Mach-O build version.
- Uses a macOS 14 runner with Xcode 15.x so the genuine Godot 4.7 minimum, iOS 14.0, remains buildable.
- Rejects targets below iOS 14.0 instead of creating a misleading IPA whose plist says iOS 9 while its engine binary requires iOS 14.
- Targets both iPhone and iPad.
