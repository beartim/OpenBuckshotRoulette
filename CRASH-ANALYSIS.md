# Native Metal crash analysis

Device and OS:

- iPad7,11 (A10-class device)
- iOS 14.3

The two supplied native-Metal crash reports have different application UUIDs,
but exactly the same application-relative crashing frames:

- `+42452760`
- `+15662400`
- `+15655412`

Both terminate on the main thread with `EXC_BAD_ACCESS / KERN_INVALID_ADDRESS
0x118`, less than one second after launch. The OpenGL build runs successfully.
This strongly isolates the failure to the RenderingDevice/native-Metal startup
path rather than signing, game scripts, bundle resources, or deployment target.

The reports are not symbolicated. A source-level native-Metal fix would require
the matching dSYM from that exact IPA and likely a Godot engine patch/rebuild.

## Practical workaround

Use:

```ini
renderer/rendering_method="mobile"
rendering_device/driver.ios="vulkan"
```

Godot then uses the Mobile renderer through Vulkan over MoltenVK. MoltenVK
translates Vulkan to Apple's Metal API, so this retains the modern renderer
without entering Godot's native-Metal driver that crashes on this device.

The device still injects MobileSubstrate tweaks into the process. Testing with
tweak injection disabled remains necessary before attributing every crash to
Godot itself.
