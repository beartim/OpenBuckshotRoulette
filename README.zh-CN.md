# OpenBuckshotRoulette iOS 14 本地模板构建 Action

本版本按照仓库当前实际目录结构生成：

```text
godot-4.7-ios14-xcode16.4-template/
├── godot-4.7-ios14-xcode16.4.zip
├── template-build-versions.txt
├── template-contents.txt
├── template-integrity.txt
├── xcode-environment.txt
└── ...
```

工作流不再访问另一个仓库、不再下载 Actions Artifact，也不需要
`GODOT_ARTIFACT_TOKEN`。模板直接由 `actions/checkout` 从当前仓库检出。

## 覆盖文件

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/export_presets.ios14.cfg.template
```

## Git LFS

工作流启用了 `lfs: true`，并额外运行 `git lfs pull` 和 `git lfs checkout`。
如果模板 ZIP 实际仍是 LFS 指针，工作流会在编译前明确报错，而不会等到
Godot 导出时才失败。

## 构建结果

成功后下载 Artifact：

```text
OpenBuckshotRoulette-iOS14-unsigned
```

内含：

```text
OpenBuckshotRoulette-iOS14-unsigned.ipa
```

这是未签名 IPA，需要重签名后安装。
