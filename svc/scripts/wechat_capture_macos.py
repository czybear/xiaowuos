#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "data" / "wechat-capture-latest.json"


APPLESCRIPT = r'''
global capturedTexts

on run argv
    set targetApp to item 1 of argv
    set shouldActivate to item 2 of argv
    set maxItems to item 3 of argv as integer
    set capturedTexts to {}

    tell application "System Events"
        if UI elements enabled is false then
            return "__XIAOWUOS_ERROR__ accessibility_disabled"
        end if

        if not (exists process targetApp) then
            return "__XIAOWUOS_ERROR__ app_not_running"
        end if

        tell process targetApp
            if shouldActivate is "true" then
                set frontmost to true
                delay 0.2
            end if

            repeat with targetWindow in windows
                my collectTextValue(targetWindow, maxItems)
                try
                    set allElements to entire contents of targetWindow
                    repeat with targetElement in allElements
                        my collectTextValue(targetElement, maxItems)
                        if (count of capturedTexts) is greater than or equal to maxItems then exit repeat
                    end repeat
                end try
                if (count of capturedTexts) is greater than or equal to maxItems then exit repeat
            end repeat
        end tell
    end tell

    return my joinLines(capturedTexts)
end run

on collectTextValue(targetElement, maxItems)
    if (count of capturedTexts) is greater than or equal to maxItems then return

    try
        set elementValue to value of targetElement
        if elementValue is not missing value then my appendText(elementValue as text, maxItems)
    end try

    try
        set elementName to name of targetElement
        if elementName is not missing value then my appendText(elementName as text, maxItems)
    end try
end collectTextValue

on appendText(rawText, maxItems)
    if (count of capturedTexts) is greater than or equal to maxItems then return
    set cleanText to rawText as text
    if cleanText is "" then return
    set end of capturedTexts to cleanText
end appendText

on joinLines(textItems)
    set AppleScript's text item delimiters to linefeed
    set joinedText to textItems as text
    set AppleScript's text item delimiters to ""
    return joinedText
end joinLines
'''


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Read visible text from the Mac WeChat UI for xiaowuOS digest experiments."
    )
    parser.add_argument("--app-name", default="", help="Mac app process name, usually WeChat or 微信.")
    parser.add_argument("--activate", action="store_true", help="Bring WeChat to front before reading visible text.")
    parser.add_argument("--max-items", type=int, default=600, help="Maximum raw UI text items to collect.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="JSON output path. Use '-' for stdout only.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON to stdout.")
    return parser.parse_args()


def run_osascript(app_name: str, activate: bool, max_items: int) -> str:
    command = [
        "osascript",
        "-",
        app_name,
        "true" if activate else "false",
        str(max_items),
    ]
    process = subprocess.run(
        command,
        input=APPLESCRIPT,
        text=True,
        capture_output=True,
        check=False,
    )
    if process.returncode != 0:
        error = process.stderr.strip() or process.stdout.strip() or f"osascript exited with {process.returncode}"
        raise RuntimeError(error)
    return process.stdout.strip()


def detect_app_name(explicit_name: str, activate: bool, max_items: int) -> tuple[str, str]:
    candidates = [explicit_name] if explicit_name else ["WeChat", "微信"]
    errors: list[str] = []
    for name in candidates:
        output = run_osascript(name, activate=activate, max_items=max_items)
        if output.startswith("__XIAOWUOS_ERROR__ app_not_running"):
            errors.append(f"{name}: app not running")
            continue
        return name, output
    raise RuntimeError("; ".join(errors) or "WeChat is not running")


def clean_lines(raw_output: str) -> list[str]:
    if raw_output.startswith("__XIAOWUOS_ERROR__ accessibility_disabled"):
        raise PermissionError("需要给 Codex/终端/脚本运行环境开启 macOS 辅助功能权限。")
    if raw_output.startswith("__XIAOWUOS_ERROR__ app_not_running"):
        raise RuntimeError("Mac 微信没有运行。")

    ignored = {
        "关闭",
        "最小化",
        "缩放",
        "搜索",
        "通讯录",
        "聊天",
        "收藏",
        "朋友圈",
        "视频号",
        "小程序",
    }
    lines: list[str] = []
    seen: set[str] = set()
    for line in raw_output.splitlines():
        value = " ".join(line.strip().split())
        if len(value) < 2:
            continue
        if value in ignored:
            continue
        if value in seen:
            continue
        seen.add(value)
        lines.append(value)
    return lines


def build_payload(app_name: str, lines: list[str]) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    return {
        "source": "mac-wechat-ui",
        "mode": "read-only-visible-window",
        "app_name": app_name,
        "captured_at": now,
        "count": len(lines),
        "items": [{"text": line} for line in lines],
        "notes": [
            "只读取 Mac 微信当前 UI 暴露的可见文字。",
            "不会读取微信数据库，不会发送消息，不会自动点击发送按钮。",
        ],
    }


def main() -> int:
    args = parse_args()
    try:
        app_name, raw_output = detect_app_name(args.app_name, activate=args.activate, max_items=args.max_items)
        lines = clean_lines(raw_output)
        payload = build_payload(app_name, lines)
    except PermissionError as error:
        print(json.dumps({"ok": False, "error": str(error), "kind": "permission"}, ensure_ascii=False), file=sys.stderr)
        return 2
    except RuntimeError as error:
        print(json.dumps({"ok": False, "error": str(error), "kind": "runtime"}, ensure_ascii=False), file=sys.stderr)
        return 1

    if args.output != "-":
        output_path = Path(args.output).expanduser()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.pretty or args.output == "-":
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(json.dumps({
            "ok": True,
            "app_name": payload["app_name"],
            "count": payload["count"],
            "output": args.output,
        }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
