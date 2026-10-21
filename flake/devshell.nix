{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [ config.treefmt.build.wrapper ];
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
