#!/usr/bin/env python3
"""ERGO M575 per-application profile daemon.

Solaar's own per-process rules don't work on Wayland/non-GNOME, so the active
window is detected here via Hyprland's socket2 event stream. On focus change the
matching profile from profiles.toml is applied: DPI through `solaar config`, side
buttons through `hyprctl keyword bind/unbind`.
"""
import json
import os
import re
import select
import signal
import socket
import subprocess
import sys
import time
import tomllib
from pathlib import Path

DEBOUNCE = 0.15  # activewindowv2 can fire spuriously; coalesce bursts before applying

CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "mouse" / "profiles.toml"


def log(msg):
    print(f"[m575] {msg}", file=sys.stderr, flush=True)


def run(argv, timeout):
    try:
        r = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
        if r.returncode != 0:
            log(f"{argv[0]} failed: {(r.stderr or r.stdout).strip()}")
        return r.returncode == 0, r.stdout
    except Exception as e:  # noqa: BLE001 - device/compositor may be offline; never crash the loop
        log(f"{argv[0]} error: {e}")
        return False, ""


class Profiles:
    def __init__(self, path):
        self.path = path
        self.mtime = 0
        self.load()

    def load(self):
        with open(self.path, "rb") as f:
            data = tomllib.load(f)
        dev = data.get("device", {})
        self.name = dev.get("name", "")
        self.back_button = dev.get("back_button", "mouse:275")
        self.forward_button = dev.get("forward_button", "mouse:276")
        self.middle_button = dev.get("middle_button", "mouse:274")
        self.default = data.get("default", {})
        self.apps = []
        for a in data.get("app", []):
            cre = re.compile(a["class"], re.IGNORECASE) if "class" in a else None
            tre = re.compile(a["title"], re.IGNORECASE) if "title" in a else None
            if cre or tre:
                self.apps.append((cre, tre, a))
        self.mtime = self.path.stat().st_mtime
        log(f"loaded {len(self.apps)} app profile(s) from {self.path}")

    def maybe_reload(self):
        try:
            if self.path.stat().st_mtime != self.mtime:
                self.load()
        except OSError:
            pass

    def resolve(self, cls, title):
        self.maybe_reload()
        for cre, tre, app in self.apps:
            if (cre is None or cre.search(cls)) and (tre is None or tre.search(title)):
                src = app
                break
        else:
            src = self.default
        return {
            "dpi": src.get("dpi", self.default.get("dpi")),
            "back": src.get("back"),
            "forward": src.get("forward"),
            "middle": src.get("middle"),
        }


def bind_value(button, action):
    """Hyprland `bind = ` value for a side button, or None to keep native behavior."""
    if not action:
        return None
    if "exec" in action:
        return f",{button},exec,{action['exec']}"
    if "key" in action:
        return f",{button},sendshortcut,{action.get('mods', '')},{action['key']},activewindow"
    return None


class Applier:
    def __init__(self, profiles):
        self.p = profiles
        self.dpi = None
        self.btn = {}  # button code -> last applied bind value (or None)

    def apply(self, cls, title):
        prof = self.p.resolve(cls, title)
        self._dpi(prof["dpi"])
        self._button(self.p.back_button, prof["back"])
        self._button(self.p.forward_button, prof["forward"])
        self._button(self.p.middle_button, prof["middle"])

    def _dpi(self, dpi):
        if dpi is None or dpi == self.dpi:
            return
        ok, _ = run(["solaar", "config", self.p.name, "dpi", str(dpi)], timeout=10)
        if ok:
            self.dpi = dpi
            log(f"dpi -> {dpi}")

    def _button(self, button, action):
        desired = bind_value(button, action)
        if desired == self.btn.get(button):
            return
        if self.btn.get(button) is not None:
            run(["hyprctl", "keyword", "unbind", f",{button}"], timeout=5)
        if desired is not None:
            ok, _ = run(["hyprctl", "keyword", "bind", desired], timeout=5)
            self.btn[button] = desired if ok else None
        else:
            self.btn[button] = None
        log(f"{button} -> {desired or 'native'}")

    def reset(self):
        for button, last in self.btn.items():
            if last is not None:
                run(["hyprctl", "keyword", "unbind", f",{button}"], timeout=5)


def current_window():
    ok, out = run(["hyprctl", "activewindow", "-j"], timeout=5)
    if ok:
        try:
            d = json.loads(out)
            return d.get("class", ""), d.get("title", "")
        except (json.JSONDecodeError, AttributeError):
            pass
    return "", ""


def find_socket():
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    base = Path(runtime) / "hypr"
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if sig:
        cand = base / sig / ".socket2.sock"
        if cand.exists():
            return cand
    socks = sorted(base.glob("*/.socket2.sock"), key=lambda p: p.stat().st_mtime, reverse=True)
    return socks[0] if socks else None


def event_loop(sock, applier):
    buf = b""
    pending = None
    deadline = None
    while True:
        timeout = None if deadline is None else max(0.0, deadline - time.monotonic())
        try:
            ready, _, _ = select.select([sock], [], [], timeout)
        except InterruptedError:
            continue
        if ready:
            chunk = sock.recv(65536)
            if not chunk:
                return
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                name, _, data = line.decode("utf-8", "replace").partition(">>")
                if name == "activewindow":
                    parts = data.split(",", 1)  # CLASS,TITLE — title may contain commas
                    pending = (parts[0], parts[1] if len(parts) > 1 else "")
                    deadline = time.monotonic() + DEBOUNCE
        elif pending is not None:
            applier.apply(*pending)
            pending, deadline = None, None


def main():
    def term(_signum, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, term)
    signal.signal(signal.SIGINT, term)

    profiles = Profiles(CONFIG)
    applier = Applier(profiles)
    try:
        while True:
            path = find_socket()
            if path is None:
                log("socket2 not found; retrying")
                time.sleep(2)
                continue
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                    sock.connect(str(path))
                    log(f"connected: {path}")
                    applier.apply(*current_window())
                    event_loop(sock, applier)
            except OSError as e:
                log(f"socket error: {e}")
            log("disconnected; reconnecting")
            time.sleep(1)
    finally:
        applier.reset()


if __name__ == "__main__":
    main()
