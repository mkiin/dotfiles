{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  wallpaper = "${inputs.self}/images/login/login.png";
  confTemplate = "${inputs.self}/home-manager/desktop/matugen/templates/sddm-theme.conf";

  theme = pkgs.sddm-astronaut.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.matugen ];
    # 壁紙焼き込みと matugen による custom.conf 生成。モード/スキームは
    # デスクトップ側 matugen (dark, デフォルトスキーム, index 0) と揃える
    postInstall = (old.postInstall or "") + ''
      themeDir=$out/share/sddm/themes/sddm-astronaut-theme
      chmod -R u+w "$themeDir"
      cp ${wallpaper} "$themeDir/Backgrounds/login.png"

      printf '%s\n' \
        '[config]' \
        '[templates.sddm]' \
        "input_path = '${confTemplate}'" \
        "output_path = '$themeDir/Themes/custom.conf'" \
        > matugen-build.toml
      HOME=$TMPDIR matugen image ${wallpaper} \
        --config matugen-build.toml --mode dark --source-color-index 0

      sed -i 's|^ConfigFile=.*|ConfigFile=Themes/custom.conf|' "$themeDir/metadata.desktop"
    '';
  });

  westonIni = pkgs.writeText "weston.ini" ''
    [keyboard]
    keymap_layout=us

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
    wayland.compositorCommand = "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = [ theme ];

    settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Classic";
        CursorSize = 24;
      };
      # greeter の env は sddm が空から組み立てるため PAM の XCURSOR_PATH が届かない
      General.GreeterEnvironment = "XCURSOR_PATH=/run/current-system/sw/share/icons";
    };
  };

  environment.systemPackages = [
    theme
    pkgs.bibata-cursors
  ];

  fonts.packages = [ theme ];
}
