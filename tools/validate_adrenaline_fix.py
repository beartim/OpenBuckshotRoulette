#!/usr/bin/env python3
"""Static validation for the OpenBuckshotRoulette adrenaline fix."""
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
failed = False


def read(relative: str) -> str:
    global failed
    path = root / relative
    if not path.is_file():
        print(f"FAIL: missing {path}")
        failed = True
        return ""
    return path.read_text(encoding="utf-8")


def expect(label: str, condition: bool) -> None:
    global failed
    print(f"{'PASS' if condition else 'FAIL'}: {label}")
    failed |= not condition

item_manager = read("scripts/ItemManager.gd")
item_interaction = read("scripts/ItemInteraction.gd")
hand_manager = read("scripts/HandManager.gd")
permission_manager = read("scripts/PermissionManager.gd")

# Only inspect the adrenaline steal block. The same member variables are valid
# elsewhere while regular player items are being instantiated.
steal_match = re.search(
    r"func _save_player_item_interaction_arrays\(\).*?(?=\nfunc ResetDealerGrid\()",
    item_manager,
    flags=re.DOTALL,
)
steal_block = steal_match.group(0) if steal_match else ""

expect("dealer target collector", "func _collect_dealer_steal_targets()" in steal_block)
expect("no stale indicator append in steal block", "append(temp_indicator)" not in steal_block)
expect("no stale timeout indicator in steal block", "temp_indicator.Revert()" not in steal_block)
expect("dealer item filtering", "indicator.isDealerItem" in steal_block and "itemArray_instances_dealer.has(child)" in steal_block)
expect("steal state snapshot", "var was_stealing := stealing and stealing_fs" in item_interaction)
expect(
    "inventory-safe stolen use",
    'InteractWith(temp_name if temp_name != "" else passedItemName, !was_stealing)' in item_interaction,
)
expect("validated remote removal", "func RemoveItem_Remote(activeInstance : Node3D) -> bool:" in hand_manager)
expect("paired array bounds", permission_manager.count("var pair_count := mini") >= 2)
expect("invalid instance guards", "is_instance_valid" in permission_manager and "is_instance_valid" in item_interaction)

for filename, text in {
    "ItemManager.gd": item_manager,
    "ItemInteraction.gd": item_interaction,
    "HandManager.gd": hand_manager,
    "PermissionManager.gd": permission_manager,
}.items():
    expect(f"{filename} not truncated", "class_name " in text and text.count("func ") >= 2)

raise SystemExit(1 if failed else 0)
