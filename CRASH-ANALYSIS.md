# Crash analysis and fix rationale

## Proven call chain

The matching dSYM resolves the crash to:

1. `Input::set_gravity(Vector3 const&)`
2. `-[GDTView handleMotion]`
3. `-[GDTView drawView]`
4. `main`

The exception address is `0x118`, which is characteristic of a member access through a
null `Input *this` pointer. The Godot 4.7 Apple Embedded implementation guards the Input
singleton in `perform_event()`, but its four motion update functions do not.

## Immediate workaround

Swizzle `-[GDTView handleMotion]` to a no-op from the generated app target's `dummy.cpp`.
This is appropriate because OpenBuckshotRoulette does not consume motion sensors.

## Permanent engine fix

Add a null check around `Input::get_singleton()` in all four Apple Embedded motion update
functions. This preserves sensor functionality after the Input singleton is initialized
and merely discards early startup samples.
