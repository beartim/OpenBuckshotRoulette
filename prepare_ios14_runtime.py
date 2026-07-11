#!/usr/bin/env python3
from __future__ import annotations
import argparse, re, shutil
from pathlib import Path

def set_key(text: str, section: str, key: str, value: str) -> str:
    rx = re.compile(rf"(?ms)^\[{re.escape(section)}\]\n(?P<body>.*?)(?=^\[[^\n]+\]\n|\Z)")
    m = rx.search(text)
    line = f"{key}={value}"
    if not m:
        return text.rstrip() + f"\n\n[{section}]\n\n{line}\n"
    body = m.group("body")
    krx = re.compile(rf"(?m)^{re.escape(key)}=.*$")
    body = krx.sub(line, body, count=1) if krx.search(body) else body.rstrip("\n") + f"\n{line}\n"
    return text[:m.start("body")] + body + text[m.end("body"):]

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('--project-root', default='.')
    ap.add_argument('--renderer', choices=('metal','opengl3'), default='metal')
    ap.add_argument('--log-dir', default='build/logs')
    a=ap.parse_args()
    root=Path(a.project_root).resolve(); p=root/'project.godot'
    if not p.is_file(): raise SystemExit(f'missing {p}')
    logs=(root/a.log_dir); logs.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, logs/'project.godot.before-runtime-fix')
    text=p.read_text(encoding='utf-8')
    if a.renderer=='metal':
        feature, method, driver='Mobile','mobile','metal'
    else:
        feature, method, driver='GL Compatibility','gl_compatibility','opengl3'
    text=re.sub(r'(?m)^config/features=PackedStringArray\([^\n]*\)$',
                f'config/features=PackedStringArray("4.7", "{feature}")', text, count=1)
    text=set_key(text,'rendering','renderer/rendering_method',f'"{method}"')
    text=set_key(text,'rendering','renderer/rendering_method.mobile',f'"{method}"')
    text=set_key(text,'rendering','rendering_device/driver.ios',f'"{driver}"')
    text=set_key(text,'debug','file_logging/enable_file_logging','true')
    text=set_key(text,'debug','file_logging/log_path','"user://logs/godot.log"')
    text=set_key(text,'debug','file_logging/max_log_files','5')
    text=set_key(text,'application','run/flush_stdout_on_print','true')
    p.write_text(text,encoding='utf-8')
    shutil.copy2(p, logs/'project.godot.after-runtime-fix')
    (logs/'ios-runtime-renderer.txt').write_text(f'renderer={a.renderer}\nmethod={method}\ndriver={driver}\n',encoding='utf-8')
    print(f'Prepared iOS 14 renderer: {a.renderer} ({method}/{driver})')
    return 0
if __name__=='__main__': raise SystemExit(main())
