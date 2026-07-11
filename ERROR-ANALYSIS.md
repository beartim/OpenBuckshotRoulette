# 最新链接错误分析

这次 Xcode 已进入最终 arm64 链接阶段，失败原因是数百个 Vulkan `vk*` 符号未定义，例如：

- `vkCreateInstance`
- `vkCreateMetalSurfaceEXT`
- `vkGetInstanceProcAddr`
- `vkCreateGraphicsPipelines`

虽然项目运行时被设置为 Godot 原生 Metal，但自编译模板中的 `libgodot.a` 是在启用 Vulkan 驱动的情况下构建的。Godot 的驱动注册对象会让 Vulkan 相关目标文件进入最终链接，因此仍需要 MoltenVK 提供这些符号。

上一版删除 `project.pbxproj` 中的 MoltenVK 引用会使链接必然失败。正确做法是：

1. 保持运行时配置为 `rendering_device/driver.ios="metal"`；
2. 保留 Xcode 工程中的 `MoltenVK.xcframework` 引用；
3. 在构建前注入 Khronos 的静态 MoltenVK XCFramework；
4. 运行时不会因为链接了 MoltenVK 就自动选择 Vulkan，后端仍由项目设置决定。

`AudioUnit`、`CoreAudioTypes` 和 `SwiftUICore` 在本次日志中是 linker warning，不是导致失败的未定义符号来源。
