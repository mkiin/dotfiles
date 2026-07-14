{ pkgs, ... }:
let
  star-rail-theme = pkgs.callPackage ./theme.nix { };
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "star-rail";
    # extraPackages は greeter の QML import 用（テーマ Main.qml が読む Qt モジュール）。
    # テーマ本体はここには入らない（下の systemPackages 経由でないと ThemeDir に出ない）。
    extraPackages = with pkgs.kdePackages; [
      qt5compat
      qtmultimedia
      qtsvg
    ];
  };

  # sddm モジュールは environment.pathsToLink = "/share/sddm" で systemPackages 内の
  # share/sddm/themes/* だけを ThemeDir に張る。テーマの配送経路はこれのみ。
  environment.systemPackages = [ star-rail-theme ];
}
