# OpenBuckshotRoulette iOS 14 MoltenVK 修复

## 本次错误

Xcode 已正确读取工程，但构建失败：

```text
There is no XCFramework found at 'build/ios/MoltenVK.xcframework'
```

自编译 Godot 模板 ZIP 内没有 `MoltenVK.xcframework`，而 Xcode 工程仍引用它。

## 修复方式

工作流从 KhronosGroup/MoltenVK 官方 v1.3.0 Release 下载
`MoltenVK-all.tar`，提取静态 `MoltenVK.xcframework`，在 Godot 导出后复制到
生成的 `.xcodeproj` 同级目录。随后才运行 Xcode。

使用 v1.3.0 是为了避免使用由更新 Xcode 工具链编译的 MoltenVK；该版本发布说明
包含使用 Xcode 14 的 legacy build，能与当前 Xcode 16.4/iOS 14 构建链兼容。

## 覆盖文件

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/export_presets.ios14.cfg.template
```

提交后重新运行 `Build OpenBuckshotRoulette iOS 14 IPA`。

## 长期修复

更干净的做法是在重新编译 Godot 模板时，先安装 Vulkan SDK/MoltenVK，并向 SCons
传入 `vulkan_sdk_path`，让 `generate_bundle=yes` 直接把
`MoltenVK.xcframework` 放进模板 ZIP。当前修复无需再次编译 100 MB Godot 模板。
