# OpenBuckshotRoulette iOS 14：Godot 直接 Xcode 工程输出修复

## 本次错误

Godot 实际已经完成 iOS 导出，并生成：

```text
build/ios/OpenBuckshotRoulette.xcodeproj
build/ios/OpenBuckshotRoulette/
build/ios/OpenBuckshotRoulette.xcframework/
```

但旧脚本只接受：

```text
build/ios/OpenBuckshotRoulette.zip
```

所以在导出成功后错误退出：

```text
error: Godot did not create the iOS Xcode-project ZIP.
```

## 修复

新版 `build_ios14.sh` 同时支持：

1. `application/export_project_only=true` 生成的直接 Xcode 工程；
2. 旧版或其他模板生成的 ZIP Xcode 工程。

它会优先使用直接生成的 `.xcodeproj`，只有找不到时才解压 ZIP。

## 覆盖文件

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/export_presets.ios14.cfg.template
```

真正必须更新的是 `ios_port/build_ios14.sh`；其余两个文件一并提供，避免版本混用。

## 提交

```bash
git add .github/workflows/build-ios.yml
git add ios_port/build_ios14.sh
git add ios_port/export_presets.ios14.cfg.template
git update-index --chmod=+x ios_port/build_ios14.sh
git commit -m "Accept direct Godot iOS Xcode project export"
git push
```
