# Crash analysis

- Device: iPad7,11, iOS 14.3
- Exception: EXC_BAD_ACCESS / SIGSEGV at 0x118
- Launch-to-crash: ~0.86 s
- Main binary UUID: 6b6f8a72-d190-3da1-b940-851b2714a715
- App offsets: 0x287c718, 0xef0d40, 0xeef1f4
- Multiple MobileSubstrate dylibs were injected

The build is changed from Forward Plus + MoltenVK/Vulkan to native Metal Mobile, with GL Compatibility available as a fallback. Matching symbols are now retained for exact symbolication of any subsequent crash.
