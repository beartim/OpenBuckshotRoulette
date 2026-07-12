#!/usr/bin/env python3
"""Apply repeatable iOS compatibility changes to OpenBuckshotRoulette."""
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


FONT_FALLBACK_SCRIPT = 'extends Node\n\nconst SC_FONT_PATH := "res://fonts/fonts language/NotoSansSC-Regular_simplified chinese_new.ttf"\nconst TC_FONT_PATH := "res://fonts/fonts language/NotoSansTC-Regular_traditional chinese_new.ttf"\nconst FONT_THEME_ITEMS := [\n\t"font",\n\t"normal_font",\n\t"bold_font",\n\t"italics_font",\n\t"bold_italics_font",\n\t"mono_font",\n]\nconst FONT_CONTAINER_CLASSES := {\n\t"Theme": true,\n\t"LabelSettings": true,\n\t"TextMesh": true,\n}\n\nvar _sc_font: Font\nvar _tc_font: Font\nvar _system_cjk_font: SystemFont\nvar _ordered_fallbacks: Array[Font] = []\nvar _visited_resources: Dictionary = {}\n\n\nfunc _enter_tree() -> void:\n\t_sc_font = _load_font(SC_FONT_PATH)\n\t_tc_font = _load_font(TC_FONT_PATH)\n\n\t_system_cjk_font = SystemFont.new()\n\t_system_cjk_font.font_names = PackedStringArray([\n\t\t"PingFang SC",\n\t\t"PingFang TC",\n\t\t"Hiragino Sans GB",\n\t\t"Heiti SC",\n\t\t"Arial Unicode MS",\n\t])\n\t_system_cjk_font.allow_system_fallback = true\n\n\t_rebuild_fallback_order()\n\tif _ordered_fallbacks.is_empty():\n\t\tpush_error("iOS CJK font fallback could not load any usable font.")\n\t\treturn\n\n\t# Covers controls that do not provide their own theme font.\n\tThemeDB.fallback_font = _ordered_fallbacks[0]\n\n\tget_tree().node_added.connect(_on_node_added)\n\tcall_deferred("_patch_existing_tree")\n\n\nfunc _notification(what: int) -> void:\n\tif what == NOTIFICATION_TRANSLATION_CHANGED and is_inside_tree():\n\t\tcall_deferred("_refresh_after_language_change")\n\n\nfunc _load_font(path: String) -> Font:\n\tif not ResourceLoader.exists(path):\n\t\tpush_warning("CJK fallback font is missing: " + path)\n\t\treturn null\n\tvar resource := load(path)\n\tif resource is Font:\n\t\treturn resource as Font\n\tpush_warning("CJK fallback resource is not a Font: " + path)\n\treturn null\n\n\nfunc _rebuild_fallback_order() -> void:\n\t_ordered_fallbacks.clear()\n\tvar locale := TranslationServer.get_locale().to_lower()\n\tvar use_traditional_first := (\n\t\tlocale.contains("zht")\n\t\tor locale.contains("hant")\n\t\tor locale.begins_with("zh_tw")\n\t\tor locale.begins_with("zh-tw")\n\t\tor locale.begins_with("zh_hk")\n\t\tor locale.begins_with("zh-hk")\n\t\tor locale.begins_with("zh_mo")\n\t\tor locale.begins_with("zh-mo")\n\t)\n\n\tif use_traditional_first:\n\t\t_append_if_valid(_tc_font)\n\t\t_append_if_valid(_sc_font)\n\telse:\n\t\t_append_if_valid(_sc_font)\n\t\t_append_if_valid(_tc_font)\n\t_append_if_valid(_system_cjk_font)\n\n\nfunc _append_if_valid(font: Font) -> void:\n\tif font != null and not _ordered_fallbacks.has(font):\n\t\t_ordered_fallbacks.append(font)\n\n\nfunc _refresh_after_language_change() -> void:\n\t_rebuild_fallback_order()\n\t_visited_resources.clear()\n\tif not _ordered_fallbacks.is_empty():\n\t\tThemeDB.fallback_font = _ordered_fallbacks[0]\n\t_patch_existing_tree()\n\n\nfunc _on_node_added(node: Node) -> void:\n\t_patch_node(node)\n\n\nfunc _patch_existing_tree() -> void:\n\t_visited_resources.clear()\n\tvar project_theme := ThemeDB.get_project_theme()\n\tif project_theme != null:\n\t\t_patch_resource(project_theme)\n\t_patch_node_recursive(get_tree().root)\n\n\nfunc _patch_node_recursive(node: Node) -> void:\n\t_patch_node(node)\n\tfor child in node.get_children():\n\t\t_patch_node_recursive(child)\n\n\nfunc _patch_node(node: Node) -> void:\n\t# Patch fonts stored directly in properties such as Label3D.font,\n\t# Label.label_settings, Control.theme and theme font overrides.\n\tfor property_info in node.get_property_list():\n\t\tif int(property_info.get("type", TYPE_NIL)) != TYPE_OBJECT:\n\t\t\tcontinue\n\t\tvar property_name := StringName(property_info.get("name", ""))\n\t\tif property_name == &"":\n\t\t\tcontinue\n\t\t_patch_value(node.get(property_name))\n\n\t# Also patch effective inherited theme fonts, not only local overrides.\n\tif node is Control:\n\t\tvar control := node as Control\n\t\tfor item_name in FONT_THEME_ITEMS:\n\t\t\tif control.has_theme_font(item_name):\n\t\t\t\t_patch_font(control.get_theme_font(item_name))\n\t\tcontrol.queue_redraw()\n\n\nfunc _patch_value(value: Variant) -> void:\n\tif value is Font:\n\t\t_patch_font(value as Font)\n\telif value is Resource:\n\t\tvar resource := value as Resource\n\t\tif FONT_CONTAINER_CLASSES.has(resource.get_class()):\n\t\t\t_patch_resource(resource)\n\telif value is Array:\n\t\tfor entry in value:\n\t\t\t_patch_value(entry)\n\telif value is Dictionary:\n\t\tfor entry in value.values():\n\t\t\t_patch_value(entry)\n\n\nfunc _patch_resource(resource: Resource) -> void:\n\tif resource == null:\n\t\treturn\n\tvar instance_id := resource.get_instance_id()\n\tif _visited_resources.has(instance_id):\n\t\treturn\n\t_visited_resources[instance_id] = true\n\n\tfor property_info in resource.get_property_list():\n\t\tvar usage := int(property_info.get("usage", 0))\n\t\tif (usage & PROPERTY_USAGE_STORAGE) == 0:\n\t\t\tcontinue\n\t\tvar property_name := StringName(property_info.get("name", ""))\n\t\tif property_name == &"":\n\t\t\tcontinue\n\t\t_patch_value(resource.get(property_name))\n\n\nfunc _patch_font(font: Font) -> void:\n\tif font == null or _ordered_fallbacks.has(font):\n\t\treturn\n\n\t# Preserve upstream fallback fonts, remove our previous ordering, then append\n\t# the locale-appropriate Simplified/Traditional chain and iOS system fallback.\n\tvar merged: Array[Font] = []\n\tfor existing in font.fallbacks:\n\t\tif existing != null and not _ordered_fallbacks.has(existing):\n\t\t\tmerged.append(existing)\n\tfor fallback in _ordered_fallbacks:\n\t\tif fallback != font and not merged.has(fallback):\n\t\t\tmerged.append(fallback)\n\n\tif font.fallbacks != merged:\n\t\tfont.fallbacks = merged\n'

MOD_FUNCTION = '''func _get_mod_directories() -> Array[String]:
\tvar dirs: Array[String] = []
\tdirs.append("user://mods/")

\t# The iOS application bundle is read-only. Keep mods inside the app sandbox.
\tif OS.has_feature("ios") or OS.has_feature("iOS"):
\t\treturn dirs

\tvar exec_dir := OS.get_executable_path().get_base_dir()
\tdirs.append(exec_dir.path_join("mods"))

\t# /sdcard is Android-specific, not a generic mobile path.
\tif OS.has_feature("android"):
\t\tdirs.append("/sdcard/open_buckshot_roulette/mods/")

\treturn dirs
'''


def backup(root: Path, file_path: Path) -> None:
    backup_path = root / ".ios-port-backup" / file_path.relative_to(root)
    if not backup_path.exists():
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file_path, backup_path)


def patch_mod_loader(root: Path) -> bool:
    path = root / "scripts" / "ModLoader.gd"
    if not path.is_file():
        raise FileNotFoundError(f"Missing upstream file: {path}")
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"func _get_mod_directories\(\) -> Array\[String\]:\n.*?(?=\nfunc _scan_mods_from_dir)",
        flags=re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        raise RuntimeError("Could not locate ModLoader._get_mod_directories(); upstream may have changed.")
    replacement = MOD_FUNCTION.rstrip("\n")
    if match.group(0) == replacement:
        return False
    backup(root, path)
    path.write_text(pattern.sub(replacement, text, count=1), encoding="utf-8")
    return True


def ensure_input_devices_section(text: str) -> str:
    values = (
        "[input_devices]\n\n"
        "pointing/emulate_mouse_from_touch=true\n"
        "pointing/emulate_touch_from_mouse=false\n\n"
    )
    if "[input_devices]" not in text:
        marker = "\n[input]\n"
        if marker not in text:
            raise RuntimeError("Could not locate [input] section in project.godot")
        return text.replace(marker, "\n" + values + "[input]\n", 1)

    # Update or append settings inside an existing section.
    section_re = re.compile(r"\[input_devices\]\n(?P<body>.*?)(?=\n\[|\Z)", re.DOTALL)
    match = section_re.search(text)
    if not match:
        raise RuntimeError("Malformed [input_devices] section")
    body = match.group("body")
    settings = {
        "pointing/emulate_mouse_from_touch": "true",
        "pointing/emulate_touch_from_mouse": "false",
    }
    for key, value in settings.items():
        setting_re = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
        if setting_re.search(body):
            body = setting_re.sub(f"{key}={value}", body)
        else:
            body = body.rstrip() + f"\n{key}={value}\n"
    return text[: match.start("body")] + body + text[match.end("body") :]


def patch_project_settings(root: Path) -> bool:
    path = root / "project.godot"
    if not path.is_file():
        raise FileNotFoundError(f"Missing upstream file: {path}")
    text = path.read_text(encoding="utf-8")
    updated = ensure_input_devices_section(text)
    if updated == text:
        return False
    backup(root, path)
    path.write_text(updated, encoding="utf-8")
    return True



def ensure_autoload(text: str, name: str, resource_path: str) -> str:
    line = f'{name}="*{resource_path}"'
    section_re = re.compile(r"\[autoload\]\n(?P<body>.*?)(?=\n\[|\Z)", re.DOTALL)
    match = section_re.search(text)
    if not match:
        marker = "\n[debug]\n"
        section = f"\n[autoload]\n\n{line}\n"
        if marker in text:
            return text.replace(marker, section + marker, 1)
        return text.rstrip() + section + "\n"

    body = match.group("body")
    entry_re = re.compile(rf"^{re.escape(name)}=.*$", re.MULTILINE)
    if entry_re.search(body):
        body = entry_re.sub(line, body)
    else:
        body = body.rstrip() + "\n" + line + "\n"
    return text[: match.start("body")] + body + text[match.end("body") :]


def install_cjk_font_fallback(root: Path) -> bool:
    required_fonts = [
        root / "fonts" / "fonts language" / "NotoSansSC-Regular_simplified chinese_new.ttf",
        root / "fonts" / "fonts language" / "NotoSansTC-Regular_traditional chinese_new.ttf",
    ]
    missing = [str(path.relative_to(root)) for path in required_fonts if not path.is_file()]
    if missing:
        raise FileNotFoundError("Missing bundled Chinese font(s): " + ", ".join(missing))

    script_path = root / "scripts" / "IOSFontFallback.gd"
    script_path.parent.mkdir(parents=True, exist_ok=True)
    script_changed = not script_path.exists() or script_path.read_text(encoding="utf-8") != FONT_FALLBACK_SCRIPT
    if script_changed:
        if script_path.exists():
            backup(root, script_path)
        script_path.write_text(FONT_FALLBACK_SCRIPT, encoding="utf-8")

    project_path = root / "project.godot"
    project_text = project_path.read_text(encoding="utf-8")
    updated = ensure_autoload(project_text, "IOSFontFallback", "res://scripts/IOSFontFallback.gd")
    project_changed = updated != project_text
    if project_changed:
        backup(root, project_path)
        project_path.write_text(updated, encoding="utf-8")

    return script_changed or project_changed

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".", help="OpenBuckshotRoulette repository root")
    args = parser.parse_args()
    root = Path(args.project_root).expanduser().resolve()

    if not (root / "project.godot").exists():
        raise SystemExit(f"Not a Godot project root: {root}")

    changes = {
        "scripts/ModLoader.gd": patch_mod_loader(root),
        "project.godot touch settings": patch_project_settings(root),
        "Chinese font fallback": install_cjk_font_fallback(root),
    }
    for name, changed in changes.items():
        print(f"{'patched' if changed else 'already patched'}: {name}")
    print("iOS compatibility patch complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
