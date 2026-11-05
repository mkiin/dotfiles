let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  pkgs = import (builtins.fetchTree lock.nodes.nixpkgs.locked) {
    system = builtins.currentSystem;
  };
  agenixSource = builtins.fetchTree lock.nodes.agenix.locked;
  agenix = pkgs.callPackage (agenixSource + "/pkgs/agenix.nix") { };
in
pkgs.mkShellNoCC {
  packages = map pkgs.lib.getBin [
    pkgs.python3
    pkgs.age
    pkgs.openssh
    pkgs.gitMinimal
    pkgs.mkpasswd
    agenix
  ];
}
