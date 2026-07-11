# GitHub Actions 29157863459 failure analysis

The Node.js warning was not the build failure.

The actual failure occurred after Godot generated the iOS Xcode project and
immediately invoked `xcodebuild archive` itself:

- `CFPropertyListCreateFromXMLData(): ... missing semicolon ... line 54`
- `Unable to read project 'OpenBuckshotRoulette.xcodeproj'`
- `The project ... is damaged and cannot be opened due to a parse error`
- `Project export for preset "iOS" failed`

## Changes in v3

1. Set `application/export_project_only=true` so Godot only creates the Xcode
   project. The script controls the later unsigned/signed Xcode build.
2. Stop requiring or passing `APPLE_TEAM_ID=AAAAAAAAAA` for unsigned builds.
   A Godot-only syntactic placeholder `ABCDE12XYZ` is used, then
   `DEVELOPMENT_TEAM` is cleared when `xcodebuild` runs.
3. Explicitly set `modules/camera=false`; this project does not need the iOS
   camera module or its extra framework/project entries.
4. Move the ATS WebSocket exception out of `export_presets.cfg` and safely add
   it to the generated Info.plist with Python `plistlib`.
5. Validate `project.pbxproj` with `plutil -lint` before Xcode is invoked.
6. Save the generated PBX project, its lines 35-85, Info.plist, and lint output
   in the diagnostic artifact if another failure occurs.
