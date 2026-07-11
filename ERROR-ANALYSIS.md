# OpenBuckshotRoulette iOS 14 Metal link failure analysis

The latest log still ran the older PBX-removal script. It explicitly reports:

```text
removed 4 stale MoltenVK PBX entries
```

The final linker command contains only `-lgodot`; it contains neither
`MoltenVK.xcframework`, `libMoltenVK.a`, nor `-force_load`. Because the custom
`libgodot.a` includes the Vulkan driver, the linker then reports hundreds of
undefined `_vk*` symbols.

## Robust fix

This revision does not depend on generated Xcode PBX framework records. It:

1. Copies the static `MoltenVK.xcframework` next to the Xcode project.
2. Verifies that `libMoltenVK.a` exports `_vkCreateInstance` and
   `_vkGetInstanceProcAddr`.
3. Removes any generated MoltenVK PBX records to prevent duplicate or stale
   references.
4. Passes the static archive directly through Xcode `OTHER_LDFLAGS` using:

```text
-Wl,-force_load,/absolute/path/MoltenVK.xcframework/ios-arm64/libMoltenVK.a
```

5. Explicitly links the iOS system frameworks listed by the MoltenVK runtime
   integration guide.
6. Runs `xcodebuild -showBuildSettings` and refuses to compile unless the
   `-force_load` path is present.
7. Uses a visible script revision marker so GitHub Actions detects accidental
   deployment of an older script before the expensive Godot export begins.
