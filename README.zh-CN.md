# OpenBuckshotRoulette iOS 14 Metal 链接修复

## 覆盖文件

```text
build-ios.yml → .github/workflows/build-ios.yml
build_ios14.sh → ios_port/build_ios14.sh
prepare_ios14_runtime.py → ios_port/prepare_ios14_runtime.py
export_presets.ios14.cfg.template → ios_port/export_presets.ios14.cfg.template
```

提交：

```bash
git add .github/workflows/build-ios.yml ios_port/
git update-index --chmod=+x ios_port/build_ios14.sh
git update-index --chmod=+x ios_port/prepare_ios14_runtime.py
git commit -m "Restore MoltenVK link dependency for native Metal build"
git push
```

运行 Action 时继续选择：

```text
renderer = metal
```

新版会下载 Khronos MoltenVK v1.3.0，将静态 `MoltenVK.xcframework` 注入 Godot 生成的 Xcode 工程目录，并保留 PBX 中的 MoltenVK 引用。运行时仍使用原生 Metal，而不是 Vulkan。
