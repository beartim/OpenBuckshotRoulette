# OpenBuckshotRoulette iOS 14 运动传感器启动崩溃修复

## 已精确定位的根因

符号包和 Vulkan 崩溃 IPA 的 UUID 完全一致。符号化后的调用链为：

```text
GDTView.drawView
  -> GDTView.handleMotion
    -> DisplayServerAppleEmbedded.update_gravity
      -> Input::set_gravity
```

Godot 4.7 的 Apple Embedded 代码在每帧调用 `handleMotion`，但四个运动传感器
更新函数直接使用 `Input::get_singleton()`，没有检查它是否已经创建。iOS 14.3
设备上的启动时序使 CoreMotion 回调先于 Input 单例就绪，于是通过空指针访问
成员偏移 `0x118`，产生 `EXC_BAD_ACCESS`。

## 方案 A：立即测试，不重编 Godot 模板

覆盖以下文件：

```text
.github/workflows/build-ios.yml
ios_port/build_ios14.sh
ios_port/prepare_ios14_runtime.py
ios_port/export_presets.ios14.cfg.template
```

构建脚本会在 Godot 导出后，把一段 Objective-C Runtime 替换逻辑写入 Xcode
工程原本就会编译的 `dummy.cpp`，在应用启动前将 `-[GDTView handleMotion]`
替换成空函数。

OpenBuckshotRoulette 不使用重力计、加速度计、磁力计或陀螺仪，因此禁用这些
传感器不会影响游戏功能。Metal、Vulkan 和 OpenGL 三种 Action 选项都可使用。

提交后重新运行 Action：

```bash
git add .github/workflows/build-ios.yml ios_port/
git update-index --chmod=+x ios_port/build_ios14.sh
git update-index --chmod=+x ios_port/prepare_ios14_runtime.py
git commit -m "Work around Godot iOS motion startup crash"
git push
```

新日志必须出现：

```text
Build script revision: 2026-07-12-motion-sensor-workaround-v1
OPENBUCKSHOT_GODOT47_DISABLE_MOTION_V1
```

先测试 `renderer=metal`，再测试 `renderer=vulkan`。

## 方案 B：永久修复，自编译新 Godot 模板

运行：

```text
.github/workflows/build-godot-ios14-motion-fixed-template.yml
```

该工作流会在编译 Godot 4.7 之前，给 `update_gravity`、
`update_accelerometer`、`update_magnetometer`、`update_gyroscope` 都加入 Input
单例空指针检查，然后重新生成 iOS 14 模板。

成功后下载 Artifact：

```text
godot-4.7-ios14-motion-fixed-xcode16.4-template
```

其中的 ZIP 仍命名为：

```text
godot-4.7-ios14-xcode16.4.zip
```

用它覆盖仓库根目录现有模板 ZIP。永久修复模板使用时，方案 A 的运行时禁用
补丁可以保留，也可以从 `build_ios14.sh` 中删除；保留不会影响游戏，只是继续
禁用传感器。
