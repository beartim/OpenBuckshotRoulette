# OpenBuckshotRoulette iOS 14 Metal PBX 修复

本次日志表明 Godot 已成功导出 Xcode 工程，`ES LATAM` 路径也已修复。真正导致退出的是构建脚本自己的检查：

```text
error: Generated project still references MoltenVK for IOS_RENDERER=metal.
```

生成的 `project.pbxproj` 里只有 4 条 MoltenVK 记录，分别属于 PBXBuildFile、PBXFileReference、Frameworks build phase 和 Frameworks group；没有其他 Vulkan/MoltenVK 链接参数。

新版 `build_ios14.sh` 不再看到引用就终止，而是自动删除这些陈旧 PBX 记录，然后通过 `plutil -lint` 重新校验工程，再继续 Xcode 编译。

## 覆盖方法

最少只需覆盖：

```text
ios_port/build_ios14.sh
```

建议按压缩包目录整体覆盖，并提交：

```bash
git add .github/workflows/build-ios.yml \
        ios_port/build_ios14.sh \
        ios_port/prepare_ios14_runtime.py \
        ios_port/export_presets.ios14.cfg.template

git update-index --chmod=+x ios_port/build_ios14.sh
git update-index --chmod=+x ios_port/prepare_ios14_runtime.py

git commit -m "Remove stale MoltenVK PBX references for native Metal"
git push
```

重新运行 Action，`renderer` 选择 `metal`。
