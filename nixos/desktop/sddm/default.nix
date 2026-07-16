{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  selection = builtins.fromJSON (builtins.readFile "${inputs.self}/images/wallpaper/selection.json");
  wallpaper = "${inputs.self}/images/wallpaper/${selection.login}";
  confTemplate = "${inputs.self}/home-manager/desktop/matugen/templates/sddm-theme.conf";

  theme = pkgs.sddm-astronaut.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.matugen ];
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

      # 入力欄の背景は upstream が opacity 0.2 を直書きしており conf から不透明にできない
      sed -i -e '/config.LoginFieldBackgroundColor/{n;s/opacity: 0.2/opacity: 1.0/}' \
             -e '/config.PasswordFieldBackgroundColor/{n;s/opacity: 0.2/opacity: 1.0/}' \
             "$themeDir/Components/Input.qml"
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
