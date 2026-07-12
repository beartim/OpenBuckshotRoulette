# Vulkan crash symbolization

The uploaded symbol bundle matches the crashing application exactly:

```text
App UUID:  8C332018-ABF8-3D14-94F0-2F5F225D844C
Dsym UUID: 8C332018-ABF8-3D14-94F0-2F5F225D844C
```

Using the crash image base `0x100aa4000`, the relevant addresses symbolize as:

```text
0x103320718 -> Input::set_gravity(Vector3 const&)
0x101993d40 -> -[GDTView handleMotion]
0x1019921f4 -> -[GDTView drawView]
0x1019b530c -> main
```

The crash is an `EXC_BAD_ACCESS` at address `0x118`. The disassembly/register state is
consistent with `Input::get_singleton()` returning null and `Input::set_gravity()`
then accessing a member at offset `0x118` through the null `this` pointer.

This explains why Metal and Vulkan crash at the same relative addresses: both use the
same Apple Embedded `GDTView` frame loop and motion polling. OpenGL's different startup
timing avoids the race on the tested device but does not repair the underlying engine bug.
