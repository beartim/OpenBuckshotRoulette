# 最新构建错误分析

本次 `project.pbxproj` 已修复并可被 Xcode 正常读取，编译也已进入最终链接阶段。

真正失败发生在 Xcode 15.4 / iOS 17.5 SDK 链接 Godot 4.7 官方 iOS 静态库时。日志中的关键错误包括：

```text
Could not find or use auto-linked library 'swift_Builtin_float'
Could not find or use auto-linked framework 'SwiftUICore'
Undefined symbols: CADynamicRangeAutomatic, MTLLogStateErrorDomain,
MTLTensorDomain, MTLResidencySetDescriptor, ...
```

这些符号来自比 Xcode 15.4 更新的 Apple SDK/Swift 运行库。Godot 4.7 官方模板使用 Xcode 26 时代工具链生成，不能再由旧 Xcode 15.4 完成最终链接。

v5 改用 GitHub 的 `macos-26` Runner 和 Xcode 26，并在执行 Godot 导出前校验 Xcode 主版本。由于 Apple 公布的 Xcode 26 部署目标范围从 iOS 15 开始，v5 将最低真实系统版本设为 iOS 15.0。
