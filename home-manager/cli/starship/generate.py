#!/usr/bin/env python3
"""symbol.toml (公式ドキュメント由来) から default.nix を生成する。

手書きだと Nerd Font の Private Use Area 文字が脱落するため、
TOML を読んでそのまま nix 式に書き出す。symbol を更新するときは
symbol.toml を編集して本スクリプトを再実行する。

    nix run nixpkgs#python3 -- generate.py
"""
import os
import re

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
TOML = os.path.join(HERE, "symbol.toml")
NIX = os.path.join(HERE, "default.nix")

# TOML に無い独自設定。$schema の直後に挿入する。
CHARACTER = {
    "vimcmd_symbol": "[❯](bold green)",
    "vimcmd_replace_one_symbol": "[❯](bold green)",
    "vimcmd_replace_symbol": "[❯](bold green)",
    "vimcmd_visual_symbol": "[❯](bold green)",
}

IDENT = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_'-]*$")


def quote_key(k):
    return k if IDENT.match(k) else nix_string(k)


def nix_string(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{s}"'


def emit(key, value, indent):
    """1 エントリを nix 式に変換。単一キーの dict はドット記法で畳む。"""
    path = [key]
    while isinstance(value, dict) and len(value) == 1:
        (k, v), = value.items()
        path.append(k)
        value = v
    keypath = ".".join(quote_key(p) for p in path)

    if isinstance(value, dict):
        lines = [f"{indent}{keypath} = {{"]
        for k, v in value.items():
            lines.append(emit(k, v, indent + "  "))
        lines.append(f"{indent}}};")
        return "\n".join(lines)
    return f"{indent}{keypath} = {nix_string(value)};"


def main():
    with open(TOML, "rb") as f:
        data = tomllib.load(f)

    # $schema の直後に character を挿入しつつ順序を維持する。
    settings = {}
    for k, v in data.items():
        settings[k] = v
        if k == "$schema":
            settings["character"] = CHARACTER
    if "character" not in settings:
        settings["character"] = CHARACTER

    body = "\n".join(emit(k, v, "      ") for k, v in settings.items())
    out = (
        "{ ... }:\n"
        "{\n"
        "  programs.starship = {\n"
        "    enable = true;\n"
        "    # このファイルは generate.py が symbol.toml から生成する。直接編集しない。\n"
        "    settings = {\n"
        f"{body}\n"
        "    };\n"
        "  };\n"
        "}\n"
    )

    with open(NIX, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"wrote {NIX} ({len(settings)} top-level keys)")


if __name__ == "__main__":
    main()
