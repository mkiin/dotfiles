{ pkgs, ... }:

let
  base = pkgs.appimageTools.defaultFhsEnvArgs;

  fhs = pkgs.buildFHSEnv (
    base
    // {
      name = "fhs";

      targetPkgs =
        pkgs:
        (base.targetPkgs pkgs)
        ++ (with pkgs; [
          pkg-config
        ]);

      profile = ''
        export FHS=1
      '';

      runScript = "bash";
    }
  );
in
{
  environment.systemPackages = [
    fhs
  ];

  # AppImage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Generic non-NixOS dynamically linked binaries
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };
}
