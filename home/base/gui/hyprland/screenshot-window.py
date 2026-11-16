#!/usr/bin/env python3
"""Save the active Hyprland window screenshot under the resolved app name."""

import configparser
import json
import os
from pathlib import Path
import re
import subprocess


def steam_app_id(window):
    match = re.fullmatch(r"steam_app_(\d+)", window.get("class", ""), re.I)
    if match:
        return match.group(1)

    # Proton games can expose a non-Steam Wayland/XWayland class.
    pid = window.get("pid")
    for _ in range(12):
        if not isinstance(pid, int) or pid <= 1:
            break
        try:
            environment = Path(f"/proc/{pid}/environ").read_bytes().split(b"\0")
            for item in environment:
                match = re.fullmatch(rb"(?:SteamAppId|SteamGameId)=(\d+)", item)
                if match:
                    return match.group(1).decode("ascii")
            status = Path(f"/proc/{pid}/status").read_text()
            pid = int(re.search(r"^PPid:\s*(\d+)", status, re.M).group(1))
        except (OSError, AttributeError, ValueError):
            break
    return None


def steam_name(app_id):
    home = Path.home()
    roots = {
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".steam/root",
        Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "Steam",
    }
    libraries = set(roots)
    for root in roots:
        try:
            config = (root / "steamapps/libraryfolders.vdf").read_text(errors="replace")
        except OSError:
            continue
        for value in re.findall(r'"path"\s*"((?:\\.|[^"\\])*)"', config):
            libraries.add(Path(value.replace(r"\\", "\\")))
    for library in sorted(libraries):
        manifest = library / f"steamapps/appmanifest_{app_id}.acf"
        try:
            content = manifest.read_text(errors="replace")
        except OSError:
            continue
        match = re.search(r'"name"\s*"((?:\\.|[^"\\])*)"', content)
        if match:
            return match.group(1).replace(r'\"', '"').replace(r"\\", "\\")
    return None


def desktop_name(window_class):
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    roots = [data_home, *(Path(path) for path in data_dirs if path)]
    target = window_class.casefold()
    # Prefer exact desktop IDs, then StartupWMClass.
    matches = []
    for root in roots:
        directory = root / "applications"
        if not directory.is_dir():
            continue
        for desktop in directory.rglob("*.desktop"):
            try:
                parser = configparser.ConfigParser(interpolation=None, strict=False)
                parser.optionxform = str
                with desktop.open(encoding="utf-8-sig") as file:
                    parser.read_file(file)
                entry = parser["Desktop Entry"]
                if entry.get("Type", "Application") != "Application":
                    continue
                name = entry.get("Name", "").strip()
                if not name:
                    continue
                desktop_id = desktop.relative_to(directory).as_posix().replace("/", "-")
                if desktop_id.removesuffix(".desktop").casefold() == target:
                    return name
                if entry.get("StartupWMClass", "").casefold() == target:
                    matches.append(name)
            except (OSError, UnicodeError, configparser.Error, KeyError, ValueError):
                continue
    return matches[0] if matches else None


def safe_directory_name(name):
    # Keep names readable while disallowing path separators, controls and traversal.
    name = re.sub(r"[/\\\x00-\x1f\x7f]", "_", name).strip().strip(".")
    if not name:
        return "unknown"
    encoded = name.encode("utf-8")[:200]
    return encoded.decode("utf-8", errors="ignore").rstrip(" .") or "unknown"


def main():
    window = json.loads(subprocess.check_output(["hyprctl", "-j", "activewindow"]))
    if not window or not window.get("address"):
        return
    window_class = window.get("class") or ""
    app_id = steam_app_id(window)
    name = steam_name(app_id) if app_id else None
    if not name:
        name = desktop_name(window_class)
    if not name:
        name = window_class.rsplit(".", 1)[-1] or "unknown"
    destination = Path.home() / "Pictures/Screenshots" / safe_directory_name(name)
    subprocess.run(
        ["noctalia", "msg", "screenshot-window", "--save-to-file",
         "--directory", str(destination)],
        check=True,
    )


if __name__ == "__main__":
    main()
