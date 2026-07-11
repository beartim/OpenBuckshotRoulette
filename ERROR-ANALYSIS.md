# Error analysis

The Godot export completed and produced a valid Xcode project. PBX and Info.plist
validation also passed. The first fatal Xcode error was:

```text
error: There is no XCFramework found at '.../build/ios/MoltenVK.xcframework'.
```

The generated PBX project contains both a file reference and a Frameworks build
phase entry for `MoltenVK.xcframework`, but the custom template archive contains
no `MoltenVK.xcframework` directory.

Godot's iOS build documentation requires a static MoltenVK XCFramework to be
placed in the iOS Xcode template. Godot's `generate_bundle_apple_embedded()`
only copies MoltenVK when `detect_mvk()` finds a Vulkan SDK or framework during
template generation. The earlier template build had no such SDK, so the bundle
was incomplete.

This patch injects the official Khronos MoltenVK v1.3.0 static framework after
export and before Xcode project validation/build.
