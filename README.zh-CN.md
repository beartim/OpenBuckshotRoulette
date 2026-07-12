# OpenBuckshotRoulette iOS 14 MoltenVK force-load v2

## 本次错误

这次不是 Godot、MoltenVK 或 Xcode 编译失败。脚本已经：

1. 成功导出 Xcode 工程；
2. 成功安装 `MoltenVK.xcframework`；
3. 按设计删除 PBX 中的 4 条 MoltenVK 引用；
4. 准备通过 `OTHER_LDFLAGS=-Wl,-force_load,.../libMoltenVK.a` 显式链接。

但旧检查随后又因为 PBX 中不存在 MoltenVK 引用而主动退出，逻辑互相矛盾。

## v2 修复

- force-load 模式下，PBX 中 MoltenVK 引用应为 0。
- 验证静态库存在且非空。
- 验证 Xcode 最终 Build Settings 中包含准确的 `-force_load` 路径。
- 构建脚本修订号升级为：

```text
2026-07-12-moltenvk-force-load-v2
```

## 覆盖位置

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/prepare_ios14_runtime.py
ios_port/export_presets.ios14.cfg.template
```

提交：

```bash
git add .github/workflows/build-ios.yml \
        ios_port/build_ios14.sh \
        ios_port/prepare_ios14_runtime.py \
        ios_port/export_presets.ios14.cfg.template

git update-index --chmod=+x ios_port/build_ios14.sh
git update-index --chmod=+x ios_port/prepare_ios14_runtime.py

git commit -m "Fix contradictory MoltenVK force-load guard"
git push
```

重新运行时选择 `renderer = metal`。新日志应包含：

```text
Build script revision: 2026-07-12-moltenvk-force-load-v2
PBX MoltenVK references: 0 (expected for force-load mode)
OTHER_LDFLAGS: $(inherited) -Wl,-force_load,.../libMoltenVK.a ...
```
