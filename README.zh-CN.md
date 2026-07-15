# OpenBuckshotRoulette 肾上腺素道具修复

适用仓库：`beartim/OpenBuckshotRoulette` 当前 `main`。

## 修复的问题

- 拿起或使用肾上腺素后出现 iOS 原生闪退；
- 使用肾上腺素后，相机移动到对面但不能正常选择物品；
- 选择到已删除、非对手或已经失效的物品节点；
- 偷来的物品被错误地从玩家库存计数中再次扣除；
- 偷取超时后交互权限、手部位置或物品指示器没有正确恢复；
- 临时交互数组长度不同导致越界。

## 安装方法

将 `scripts/` 中的四个文件覆盖到项目对应位置：

```text
scripts/ItemManager.gd
scripts/ItemInteraction.gd
scripts/HandManager.gd
scripts/PermissionManager.gd
```

也可以在项目根目录应用补丁：

```bash
patch -p1 < patches/0001-fix-adrenaline-steal-state.patch
```

提交：

```bash
git add scripts/ItemManager.gd \
        scripts/ItemInteraction.gd \
        scripts/HandManager.gd \
        scripts/PermissionManager.gd

git commit -m "Fix adrenaline item stealing state"
git push
```

然后使用现有的 iOS 14 OpenGL Compatibility 工作流重新构建 IPA。本修复只修改游戏脚本，不需要重新编译 Godot 4.7 模板。

## 静态校验

从项目根目录执行：

```bash
python3 tools/validate_adrenaline_fix.py .
```

或只检查本套件：

```bash
python3 tools/validate_adrenaline_fix.py /path/to/OpenBuckshotRoulette-adrenaline-item-fix
```

## 建议测试顺序

1. 玩家持有肾上腺素，对手至少有两个不同物品；
2. 使用肾上腺素并选取对手物品，确认物品被立即使用；
3. 检查对手物品数量减少、玩家物品数量没有被错误减为负数；
4. 测试偷取手铐、锯子、香烟、药物、电话和转换器；
5. 对手没有可偷物品时使用肾上腺素，确认能自动返回而不锁死；
6. 进入偷取模式后等待 7 秒，确认超时正常恢复；
7. 连续使用两次肾上腺素，确认不会保留上一次的失效引用。

## 验证范围

已完成：

- 对当前仓库源码生成统一补丁；
- 补丁反向和正向 dry-run；
- 已知坏代码模式检查；
- 数组配对、失效对象和计数边界静态检查。

当前环境不能运行 iOS 真机，也没有与新崩溃 UUID 匹配的 dSYM，因此最终运行结果仍需用重新构建的 OpenGL IPA 真机验证。
