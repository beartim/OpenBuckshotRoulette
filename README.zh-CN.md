# iOS 14 MoltenVK 强制链接修复

## 根因

本次日志仍然运行了旧脚本，日志中出现：

```text
removed 4 stale MoltenVK PBX entries
```

最终链接命令只有 `-lgodot`，没有 `libMoltenVK.a`，所以出现大量：

```text
Undefined symbols for architecture arm64: _vkCreateInstance ...
```

## 覆盖文件

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/prepare_ios14_runtime.py
ios_port/export_presets.ios14.cfg.template
```

提交：

```bash
git add .github/workflows/build-ios.yml ios_port/
git update-index --chmod=+x ios_port/build_ios14.sh
git update-index --chmod=+x ios_port/prepare_ios14_runtime.py
git commit -m "Force-load static MoltenVK for iOS 14"
git push
```

新版 Action 会在构建前检查脚本中是否包含修订号：

```text
2026-07-12-moltenvk-force-load-v1
```

如果仓库仍是旧脚本，会立即停止并指出文件未正确覆盖。

## 新链接方式

不再依赖 `project.pbxproj` 中容易被 Godot 或补丁改写的 MoltenVK 项目引用，
而是使用绝对路径和 `-force_load` 将 `libMoltenVK.a` 直接加入最终链接。
运行时渲染器仍然可以选择 `metal`；这里的 MoltenVK 只是满足自编译
`libgodot.a` 中保留的 Vulkan符号。
