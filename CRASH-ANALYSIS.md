# 肾上腺素崩溃与偷取失效分析

## 崩溃报告

上传的 `OpenBuckshotRoulette-2026-07-15-192835.ips` 显示：

- 主线程崩溃；
- `EXC_BAD_ACCESS (SIGSEGV)`；
- 访问无效地址 `0x50`；
- App UUID：`132F0D2C-8C38-3C19-91AA-0D7AB40231EB`。

当前没有与该 UUID 匹配的 dSYM，因此本次原生栈不能精确还原为函数名。不过，当前仓库源码中存在一个确定的失效对象引用错误，并且触发时机与“使用肾上腺素后进入偷取模式”完全吻合。

## 确定的源码错误

`ItemManager.SetupItemSteal()` 中原本应从每个物品节点读取：

```gdscript
var temp_indicator: PickupIndicator = child.get_child(0)
var temp_interaction: InteractionBranch = child.get_child(1)
```

但这两行被注释，随后代码仍把成员变量 `temp_indicator` 和 `temp_interaction` 加入临时数组。成员变量最后一次通常指向玩家先前生成或刚刚使用的物品；肾上腺素节点随后被 `queue_free()`，临时数组就可能保存一个已释放对象。

之后 `EnablePermissions()` 会立即遍历这些数组并写入 `interactionAllowed`。在 iOS 导出版本中，这类已释放对象访问可能表现为原生 `EXC_BAD_ACCESS`，而不是只显示 GDScript 错误。

同一错误还导致另一种表现：数组中不是对手当前物品的真实 `PickupIndicator` / `InteractionBranch`，因此相机移动到对面后无法选择或拿走物品。

## 伴随状态错误

本补丁同时处理：

1. 偷取目标仅收集仍登记在 `itemArray_instances_dealer` 中的对手物品；
2. 所有临时引用在使用前通过 `is_instance_valid()` 检查；
3. 临时 Indicator/Interaction 数组按最短长度配对，避免越界；
4. 对手物品移除失败时安全退出偷取模式；
5. 偷来的物品立即使用，不再错误扣减 `amount_player`；
6. 对手物品数量与网格可用列表防止负数和重复；
7. 超时取消时只还原本次收集到的有效 Indicator；
8. 修复 `if selectedHand == "L" or "BOTH"` 永远为真的条件表达式；
9. 给肾上腺素视觉/音频回调加入空对象保护。
