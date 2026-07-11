# OpenBuckshotRoulette iOS 移植套件

适用上游：`1503Dev/OpenBuckshotRoulette`（Godot 4.7+）。本套件不是完整游戏源码，而是应复制到上游仓库根目录的 **iOS 移植补丁与构建工具**。

## 已处理的兼容点

- 修复模组目录：iOS 只扫描 `user://mods/`，不访问只读 App Bundle，也不再把 iOS 当成 Android 去访问 `/sdcard/`。
- 开启“触摸模拟鼠标”，复用项目现有 GUI/鼠标交互与最新版移动触控代码。
- 生成 Godot iOS 导出预设。
- 提供 macOS/Xcode 构建脚本：
  - `UNSIGNED=1`：生成未签名 IPA，仅供后续重签名或 CI 验证，不能直接安装。
  - 默认模式：用 Apple Development/Distribution 签名并导出可安装 IPA。
- 可选地为上游默认 `ws://buckds.1503dev.top:14122` 添加域名级 ATS 例外。发布 App Store 时建议服务端改为 `wss://`，然后关闭该例外。

## 一、准备源码

```bash
git clone https://github.com/1503Dev/OpenBuckshotRoulette.git
cd OpenBuckshotRoulette
```

把本套件里的 `ios_port/`、`patches/`、`.github/` 复制到仓库根目录。

## 二、应用 iOS 补丁

```bash
python3 ios_port/apply_ios_port.py --project-root .
```

脚本可重复执行；首次修改时会在 `.ios-port-backup/` 保存原文件。

## 三、在 Mac 上生成 IPA

要求：macOS、Xcode、Godot 4.7 与对应的 iOS Export Templates。

### 可安装的签名 IPA

先在 Xcode 登录 Apple ID，并确保 Bundle ID 对应的签名权限可用：

```bash
export APPLE_TEAM_ID="ABCDE12XYZ"             # 10 位 Team ID
export BUNDLE_ID="com.yourdomain.openbuckshot"
export EXPORT_METHOD="development"            # development / ad-hoc / app-store-connect
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

./ios_port/build_ios.sh
```

输出位置：`build/ipa/*.ipa`

若默认联机服务器仍使用明文 WebSocket，脚本默认添加域名级 ATS 例外。服务端改为 WSS 后，使用：

```bash
ALLOW_INSECURE_WS=0 ./ios_port/build_ios.sh
```

### 未签名 IPA（不能直接安装）

```bash
export APPLE_TEAM_ID="AAAAAAAAAA"              # Godot 导出器要求非空 10 位值
export BUNDLE_ID="com.example.openbuckshot"
UNSIGNED=1 ./ios_port/build_ios.sh
```

未签名产物只适合：检查 iOS 编译结果、在你自己的签名工具中重签、或交给拥有证书的 Mac 完成签名。

## 四、GitHub Actions 构建

将整个套件提交到你自己的 fork，然后在 Actions 页面手动运行 **Build iOS unsigned IPA**。工作流会在 GitHub 的 macOS Runner 上生成未签名 IPA，并作为构建产物上传。

要生成签名 IPA，推荐在本地 Mac 上运行 `build_ios.sh`。不要把 `.p12` 密码、证书或 provisioning profile 直接提交到仓库。

## 当前功能状态

| 功能 | iOS 状态 | 说明 |
|---|---|---|
| 单人游戏 | 预计可用 | 纯 GDScript/Godot 资源，不依赖桌面原生库 |
| 触摸菜单/操作 | 已做基础适配 | 复用鼠标交互；仍建议真机逐场景测试点击区域与手势 |
| 手柄 | Godot 原生支持 | 需要真机验证具体映射 |
| Steam | 自动降级 | iOS 无 Steam 单例时走项目的 SteamShim/非 Steam 路径 |
| 模组 | 有限制 | 仅 `user://mods/`；iOS 没有桌面式“打开模组文件夹”体验 |
| 在线联机 | 有条件 | 默认服务器是明文 `ws://`；个人侧载可用 ATS 例外，正式发布应换 `wss://` |
| App Store 发布 | 未保证 | 还涉及版权授权、隐私申报、网络安全与审核要求 |

## 重要许可提示

上游代码标注 GPL-3.0，但 README 同时说明游戏本体归 MIKE KLUBNIKA 所有，并要求使用者在 itch.io 或 Steam 账户中拥有 Buckshot Roulette。此套件仅用于技术移植，不授予你重新分发游戏美术、音频、商标或完整 IPA 的权利。公开发布前应自行取得相应授权并履行 GPL 源码义务。
