{
  inputs,
  vars,
  mylib,
}:
let
  desktopModules = [
    ../../modules/nixos/desktop

    {
      modules.desktop.fonts.enable = true;
      modules.desktop.wayland.enable = true;
      modules.secrets.desktop.enable = true;
      modules.desktop.gaming.enable = true;
    }
  ];

  hyprlandModules = [
    {
      programs.hyprland.enable = true;
    }
  ];

  hostModules = [
    ../../hosts/oregairu-yukino
  ];
in
{
  flake.nixosConfigurations.oregairu-yukino = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs vars mylib;
    };

    modules = hostModules ++ desktopModules ++ hyprlandModules;
  };
}
