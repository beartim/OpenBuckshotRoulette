# v2 GitHub Actions 修复

- 升级 `actions/checkout`：v4 → v7。
- 升级 `actions/upload-artifact`：v4 → v7。
- 显式启用 Node.js 24 action runtime。
- 使用 Godot `--import` 等待资源导入完成。
- iOS 导出目标改为 `.zip`，并解压 Xcode 工程后构建。
- 增加 Xcode/iPhoneOS SDK 检查、仓库结构检查和失败日志上传。
- 自动从 `xcodebuild -list -json` 读取 scheme。
- 无签名构建显式清空签名身份与 Team，减少 Xcode 自动签名干扰。
