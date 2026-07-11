# OpenBuckshotRoulette iOS 14 自定义模板构建套件

## 已确认的模板状态

上传的构建日志显示：

- Godot commit：`5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88`
- Xcode：16.4（16F6）
- Apple Clang：17.0.0
- iPhoneOS SDK：18.5
- iOS 14 烟雾测试对象：`minos 14.0`
- Debug 模板：构建完成
- Release 模板及 Bundle：构建完成

日志中的大量 `duplicate member name` 是 Apple `libtool` 合并静态库时的警告，最终显示 `scons: done building targets`，不影响模板生成。

## 使用方法

把套件中的三个文件复制到 OpenBuckshotRoulette 仓库：

```text
.github/workflows/build-ios14.yml
ios_port/build_ios14.sh
ios_port/export_presets.ios14.cfg.template
```

提交：

```bash
git add .github/workflows/build-ios14.yml
git add ios_port/build_ios14.sh
git add ios_port/export_presets.ios14.cfg.template
git update-index --chmod=+x ios_port/build_ios14.sh
git commit -m "Build OpenBuckshotRoulette for iOS 14 with custom Godot template"
git push
```

然后打开 GitHub：

```text
Actions
→ Build OpenBuckshotRoulette iOS 14 IPA
→ Run workflow
```

参数：

```text
bundle_id: com.example.openbuckshotroulette
template_artifact_name: godot-4.7-ios14-xcode16.4-template
template_run_id: 留空
```

工作流会自动查找同一仓库中最新的、尚未过期的模板 Artifact。也可以把成功的模板工作流 Run ID 填入 `template_run_id`，固定使用某一次构建。

成功产物：

```text
OpenBuckshotRoulette-iOS14-unsigned
└── OpenBuckshotRoulette-iOS14-unsigned.ipa
```

该 IPA 未签名，需要使用你自己的证书、AltStore、SideStore、Sideloadly 或其他合法签名方式签名后安装。

## Artifact 保留问题

模板工作流当前设置的保留期限是 90 天。建议把模板 ZIP 同时保存到本地，或者发布为仓库的 GitHub Release Asset。Artifact 过期后，需要重新运行模板编译工作流。
