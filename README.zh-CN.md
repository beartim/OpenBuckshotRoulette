# OpenBuckshotRoulette iOS 14 Vulkan/MoltenVK 运行时修复

## 结论

原生 Metal 版本在 iPad7,11 / iOS 14.3 上仍会于启动后约 0.8 秒发生
`EXC_BAD_ACCESS`。新的崩溃报告与旧报告虽然 UUID 不同，但应用内相对崩溃
地址完全一致。OpenGL 版本能够运行，因此最现实的高性能修复方案是：

```text
Godot Mobile renderer + Vulkan driver + MoltenVK
```

它并非 OpenGL。Godot 输出 Vulkan 命令，MoltenVK 将其转换为 Metal 命令交给
Apple GPU，因此仍使用 Metal 图形栈，但避开 Godot 4.7 的原生 Metal 驱动。

## 覆盖文件

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/prepare_ios14_runtime.py
ios_port/export_presets.ios14.cfg.template
```

提交后运行 Action，renderer 选择 `vulkan`。

成功产物：

```text
OpenBuckshotRoulette-iOS14-vulkan-unsigned
```

## 渲染模式

- `vulkan`：推荐。Mobile renderer，通过 MoltenVK 转译到 Metal。
- `opengl3`：最稳定，适合最终兜底。
- `metal`：保留用于测试，但该设备当前已重复验证会崩溃。

Vulkan 模式还会开启 `fallback_to_opengl3=true` 并关闭 Godot pipeline cache，
以减少旧 iOS 上首次启动缓存初始化带来的变量。

## 测试前

崩溃报告仍显示 SnowBoard、FPSIndicator、ShijimaInApp 等 MobileSubstrate
模块被注入。请先使用 Choicy 为应用关闭 tweak injection，或者在越狱安全模式
测试。否则不能完全排除 UIKit/Metal Hook 对结果的影响。
