{
  perSystem = { config, pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rfc-style;
        };
        stylua.enable = true;
        shfmt.enable = true;
        qmlformat.enable = true;
      };

      settings.excludes = [
        "*.lock"
        ".git/**"
        "secrets/**"
      ];
    };
    pre-commit = {
      check.enable = false;
      settings.hooks = {
        treefmt = {
          enable = false;
          package = config.treefmt.build.wrapper;
        };
        deadnix.enable = false;
        statix.enable = false;
      };
    };
  };
}
