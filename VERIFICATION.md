# Verification from supplied logs

- Xcode 16.4 / build 16F6 selected successfully.
- Apple Clang 17.0.0 selected successfully.
- iPhoneOS SDK 18.5 selected successfully.
- The smoke-test Mach-O object contains `LC_BUILD_VERSION`, platform iOS, `minos 14.0`.
- Godot source contains both device and simulator minimum 14.0 flags.
- Debug build ends with `scons: done building targets`.
- Release bundle build ends with `Generating platform/ios/generate_bundle` and `scons: done building targets`.
