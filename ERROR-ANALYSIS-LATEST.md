# Latest build error analysis

The failure is in the generated `project.pbxproj`, not Node.js, signing, or asset import.

Godot emitted this invalid PBX line for the `ES LATAM` localization:

```text
name = ES LATAM; path = ES LATAM.lproj/InfoPlist.strings;
```

OpenStep/PBX syntax requires values containing spaces to be quoted. v4 rewrites it as:

```text
name = "ES LATAM"; path = "ES LATAM.lproj/InfoPlist.strings";
```

The repair runs before `plutil -lint` and before `xcodebuild -list`.

## Why the real minimum is iOS 14, not iOS 9

Godot 4.7's iOS build configuration compiles the device engine with
`-miphoneos-version-min=14.0`. Its iOS exporter also rejects a Metal renderer
minimum below 14.0. Editing only Info.plist or the Xcode deployment-target text
does not change the minimum encoded in the precompiled Godot engine objects.
Such an IPA would still fail to load on iOS 9.
