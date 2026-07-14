{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "star-rail";
    # qt5compat/qtmultimedia/qtsvg はテーマの Main.qml が import する
    # QML モジュールを greeter プロセスへ供給するために必要
    extraPackages = with pkgs.kdePackages; [
      (pkgs.callPackage ./theme.nix { })
      qt5compat
      qtmultimedia
      qtsvg
    ];
  };
}
