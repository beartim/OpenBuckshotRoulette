# OpenBuckshotRoulette iOS 移植套件 v4

## 本次已修复

这次错误来自语言名称 `ES LATAM`。Godot 4.7 把带空格的名称和路径直接写进
`project.pbxproj`，但没有添加引号，导致 Xcode 报 `missing semicolon`。

v4 会在 Xcode 读取工程前自动把它修复为：

```text
name = "ES LATAM";
path = "ES LATAM.lproj/InfoPlist.strings";
```

修复器不是只处理这一种语言，而是会处理所有未加引号且包含空格的 PBX
`name` 和 `path` 字段。

## 最低 iOS 版本

本套件把可真实运行的最低版本设置为 **iOS 15.0**。工作流、Godot 导出预设、
Xcode 构建参数、Info.plist 和最终 Mach-O 都会进行设置或校验。

无法把 Godot 4.7 版本真实降到 iOS 9.0，原因是官方 iOS 引擎模板本身以
`-miphoneos-version-min=15.0` 编译，并且 Metal 渲染器要求 iOS 14 以上。
只把 Info.plist 改成 9.0 会生成“看起来支持 iOS 9、实际无法启动”的 IPA，
所以 v4 会拒绝低于 15.0 的目标。

真正支持 iOS 9 需要把整个项目从 Godot 4.7 反向移植到旧版 Godot，替换渲染、
脚本和资源格式，并使用旧 Xcode/SDK 重新编译引擎；这不是修改一个版本号即可完成。

## 覆盖文件

将套件中的以下目录复制到完整项目根目录：

```text
.github/workflows/build-ios.yml
ios_port/build_ios.sh
ios_port/export_presets.cfg.template
```

提交并推送：

```bash
git add .github/workflows/build-ios.yml ios_port/build_ios.sh ios_port/export_presets.cfg.template
git update-index --chmod=+x ios_port/build_ios.sh
git commit -m "Fix iOS PBX localization paths and deployment target"
git push
```

在 GitHub Actions 手动运行时，`ios_deployment_target` 保持 `15.0`。
构建成功后下载 `OpenBuckshotRoulette-iOS-unsigned`。

## v6：iOS 中文方框修复

v6 会在构建前自动安装 `IOSFontFallback` Autoload。它保留游戏原来的英文字体，只在原字体找不到中文字形时依次使用项目自带的 Noto Sans SC/TC 和 iOS PingFang 系统字体。

无需手工修改每个 `.tscn`。覆盖 v6 的 `ios_port` 与工作流文件后重新构建即可。
