{ pkgs, ... }:
let
  # electron 43.3 以降は StatusNotifierItem を D-Bus に公開できずトレイアイコンが出ない
  # (NixOS/nixpkgs#556106 / electron#52674)。上流が直るまで 42 系に固定する。
  # nixpkgs 側が package.json と electron のメジャー一致を検証するため、宣言も 42 に合わせる。
  vesktop = (pkgs.vesktop.override { electron_43 = pkgs.electron_42; }).overrideAttrs (prev: {
    # 書き換えは pnpm の lockfile 検証 (configurePhase) の後、
    # nixpkgs 側のメジャー一致検証 (preBuild 冒頭) の前でなければならない。
    preBuild = ''
      substituteInPlace package.json --replace-fail '"electron": "43' '"electron": "42'
    ''
    + (prev.preBuild or "");
  });
in
{
  environment.systemPackages = [ vesktop ];
}
