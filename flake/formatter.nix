{
  perSystem = { config, pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt;
        };
        stylua.enable = true;
        shfmt.enable = true;
        qmlformat.enable = true;
      };

      settings.excludes = [
        "*.lock"
        ".git/**"
        "secrets/**"
        "home/linux/desktop/themes/wallust/templates/**"
        "home/linux/desktop/themes/matugen/templates/**"
      ];
    };
    pre-commit = {
      check.enable = false;
      settings.hooks = {
        treefmt = {
          enable = true;
          package = config.treefmt.build.wrapper;
        };
        deadnix.enable = true;
        statix.enable = false;
      };
    };
  };
}
