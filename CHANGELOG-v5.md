# v5 变更记录

- 修复 Xcode 15.4 链接 Godot 4.7 官方 iOS 模板时出现的 Swift、Metal 和 CoreAnimation 未定义符号。
- GitHub Actions Runner 从 `macos-14` 切换为 `macos-26`。
- 自动选择已安装的最新 Xcode 26，并在构建前拒绝 Xcode 15/16。
- 最低真实部署版本改为 iOS 15.0，与 Apple 公布的 Xcode 26 部署目标范围一致。
- 新增 Xcode、iPhoneOS SDK、SDK 路径和 Swift 编译器路径诊断。
- 保留 v4 的本地化名称引号修复、PBX/Plist 校验和无签名 IPA 打包逻辑。
