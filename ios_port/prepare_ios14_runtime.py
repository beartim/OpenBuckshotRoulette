#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


def set_key(text: str, section: str, key: str, value: str) -> str:
    section_rx = re.compile(
        rf"(?ms)^\[{re.escape(section)}\]\n(?P<body>.*?)(?=^\[[^\n]+\]\n|\Z)"
    )
    match = section_rx.search(text)
    line = f"{key}={value}"
    if not match:
        return text.rstrip() + f"\n\n[{section}]\n\n{line}\n"

    body = match.group("body")
    key_rx = re.compile(rf"(?m)^{re.escape(key)}=.*$")
    if key_rx.search(body):
        body = key_rx.sub(line, body, count=1)
    else:
        body = body.rstrip("\n") + f"\n{line}\n"
    return text[: match.start("body")] + body + text[match.end("body") :]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".")
    parser.add_argument(
        "--renderer",
        choices=("vulkan", "metal", "opengl3"),
        default="vulkan",
    )
    parser.add_argument("--log-dir", default="build/logs")
    args = parser.parse_args()

    root = Path(args.project_root).resolve()
    project = root / "project.godot"
    if not project.is_file():
        raise SystemExit(f"missing {project}")

    logs = root / args.log_dir
    logs.mkdir(parents=True, exist_ok=True)
    shutil.copy2(project, logs / "project.godot.before-runtime-fix")

    text = project.read_text(encoding="utf-8")
    if args.renderer == "vulkan":
        feature = "Mobile"
        method = "mobile"
        driver = "vulkan"
    elif args.renderer == "metal":
        feature = "Mobile"
        method = "mobile"
        driver = "metal"
    else:
        feature = "GL Compatibility"
        method = "gl_compatibility"
        driver = "opengl3"

    text = re.sub(
        r'(?m)^config/features=PackedStringArray\([^\n]*\)$',
        f'config/features=PackedStringArray("4.7", "{feature}")',
        text,
        count=1,
    )
    text = set_key(
        text, "rendering", "renderer/rendering_method", f'"{method}"'
    )
    text = set_key(
        text, "rendering", "renderer/rendering_method.mobile", f'"{method}"'
    )
    text = set_key(
        text, "rendering", "rendering_device/driver.ios", f'"{driver}"'
    )
    text = set_key(
        text,
        "rendering",
        "rendering_device/fallback_to_opengl3",
        "true",
    )
    # Avoid reusing a native-Metal pipeline cache created by an older build.
    # Vulkan/MoltenVK maintains its own driver cache underneath Godot.
    text = set_key(
        text,
        "rendering",
        "rendering_device/pipeline_cache/enable",
        "false" if args.renderer == "vulkan" else "true",
    )
    text = set_key(text, "debug", "file_logging/enable_file_logging", "true")
    text = set_key(text, "debug", "file_logging/log_path", '"user://logs/godot.log"')
    text = set_key(text, "debug", "file_logging/max_log_files", "5")
    text = set_key(text, "application", "run/flush_stdout_on_print", "true")

    project.write_text(text, encoding="utf-8")
    shutil.copy2(project, logs / "project.godot.after-runtime-fix")
    (logs / "ios-runtime-renderer.txt").write_text(
        "\n".join(
            [
                f"renderer={args.renderer}",
                f"method={method}",
                f"driver={driver}",
                "fallback_to_opengl3=true",
                f"pipeline_cache={'false' if args.renderer == 'vulkan' else 'true'}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(f"Prepared iOS 14 renderer: {args.renderer} ({method}/{driver})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
