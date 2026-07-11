# iOS Port Status

## 技术判断

该项目是 Godot 4.7 的 GDScript/GDShader 工程，主体无需改写为 Swift/Objective-C。iOS 移植的主路径是：修复平台路径与触控输入 → Godot 导出 Xcode 工程 → Xcode 编译、签名和导出 IPA。

## 已知风险

1. **场景级触控**：全局触摸转鼠标可覆盖大部分 Control/点击交互，但 3D 拖拽、长按、双指和鼠标锁定逻辑仍需真机逐项验证。
2. **默认联机地址**：源码使用 `ws://buckds.1503dev.top:14122`。ATS 例外适合个人测试，不是理想的生产方案；正式版应部署 TLS/WSS。
3. **模组导入**：iOS 沙盒不能像桌面端一样直接打开可写的可执行目录。当前仅保留 `user://mods/`；若要面向普通用户安装模组，需要增加 UIDocumentPicker 或“文件”App 导入流程。
4. **Steam**：iOS 没有桌面 Steamworks。项目的 SteamShim 会在 Steam 单例不存在时降级，但所有 Steam 专属功能都必须按“不可用”测试。
5. **GPU/着色器**：项目声明 Forward Plus 并包含 GDShader。iPhone 真机通常可走 iOS 图形后端，但低端设备、透明效果和自定义 shader 仍需性能测试；iOS Simulator 只支持 Compatibility renderer。
6. **法律与商店审核**：源码许可证不自动覆盖原游戏资产、名称和音频。技术上能编译，不等于有权分发或能通过 App Store 审核。
