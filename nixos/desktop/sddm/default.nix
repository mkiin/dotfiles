{
  pkgs,
  lib,
  config,
  ...
}:
let
  star-rail-theme = pkgs.callPackage ./theme.nix { };

  xkb = config.services.xserver.xkb;
  # greeter の weston を DP-2 のみに限定する。既定の weston.ini は出力設定を持たず
  # 全モニタにまたがるため、他の 3 出力(DP-1/DP-3/HDMI-A-1)を mode=off で無効化。
  # 出力が 1 枚になることでログイン画面は DP-2 だけに出て、マウスも画面外へ出られなくなる。
  # libinput/keyboard は上流モジュールが生成する内容を config から引いて再現している。
  westonIni = pkgs.writeText "weston.ini" ''
    [libinput]
    enable-tap=${lib.boolToString config.services.libinput.mouse.tapping}
    left-handed=${lib.boolToString config.services.libinput.mouse.leftHanded}

    [keyboard]
    keymap_model=${xkb.model}
    keymap_layout=${xkb.layout}
    keymap_variant=${xkb.variant}
    keymap_options=${xkb.options}

    [output]
    name=DP-1
    mode=off

    [output]
    name=DP-3
    mode=off

    [output]
    name=HDMI-A-1
    mode=off
  '';
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "star-rail";
    wayland.compositorCommand = "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
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
