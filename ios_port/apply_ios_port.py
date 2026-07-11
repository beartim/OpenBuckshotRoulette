#!/usr/bin/env python3
"""Apply repeatable iOS compatibility changes to OpenBuckshotRoulette."""
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".", help="OpenBuckshotRoulette repository root")
    args = parser.parse_args()
    root = Path(args.project_root).expanduser().resolve()

    if not (root / "project.godot").exists():
        raise SystemExit(f"Not a Godot project root: {root}")

    changes = {
        "scripts/ModLoader.gd": patch_mod_loader(root),
        "project.godot": patch_project_settings(root),
    }
    for name, changed in changes.items():
        print(f"{'patched' if changed else 'already patched'}: {name}")
    print("iOS compatibility patch complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
