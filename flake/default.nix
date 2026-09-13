{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule

    ./writers.nix
    ./formatter.nix
    ./checks.nix
    ./devshell.nix
    ./apps
    ./hosts
  ];

  systems = [
    "x86_64-linux"
  ];

  _module.args.vars = import ../vars;
}
