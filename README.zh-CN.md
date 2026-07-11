# iOS 14 启动闪退修复

崩溃日志显示应用在 iPad7,11、iOS 14.3 上启动约 0.86 秒后，主线程发生 `EXC_BAD_ACCESS`。这不是签名、最低系统版本或 dyld 缺库错误；Godot 工作线程、音频和运动线程均已建立。旧 IPA 没有匹配 dSYM，因此当前地址无法精确符号化。

项目原本使用 Forward Plus，并通过 MoltenVK 进入 Vulkan/RenderingDevice。新构建默认改为：

- `metal`：Mobile renderer + Godot 原生 Metal，完全不链接 MoltenVK；先测试这个。
- `opengl3`：GL Compatibility + OpenGL 3；若 Metal 仍闪退，用这个兜底。高级 shader 或粒子效果可能降级。

覆盖：

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/prepare_ios14_runtime.py
ios_port/export_presets.ios14.cfg.template
```

提交后运行 Action，先选 `metal`。新版还会上传 `*-symbols`，包含 dSYM、Link Map 和 UUID。

**测试前必须为该应用关闭 tweak injection，或在越狱安全模式测试。** 这份 `.ips` 显示进程中注入了 Substrate、SnowBoard、FPSIndicator、ShijimaInApp 等多个第三方动态库，插件冲突不能通过重新编译游戏本身消除。

新版开启 Godot 文件日志，并在 Info.plist 中开启文件共享。若日志初始化成功，可从应用 Documents 中读取：

```text
logs/godot.log
```
