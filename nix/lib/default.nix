{ inputs }:

let
  inherit (inputs.nixpkgs.lib) hasSuffix;
  hm = inputs.home-manager;

  homeDir = { system, username }:
    if hasSuffix "darwin" system
    then "/Users/${username}"
    else "/home/${username}";

  dotfilesDirOf = { system, username }:
    "${homeDir { inherit system username; }}/ghq/github.com/${username}/dotfiles";

  coreModule = { system, username }:
    let home = homeDir { inherit system username; };
    in {
      home.username      = username;
      home.homeDirectory = home;
      home.stateVersion  = "25.11";
    };
in
{
  mkHome = { system, username, modules ? [] }:
    let
      home        = homeDir { inherit system username; };
      dotfilesDir = dotfilesDirOf { inherit system username; };
    in
    hm.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit inputs username dotfilesDir system; };
      modules = [
        (coreModule { inherit system username; })
        ./dotlink.nix
        ../modules/home
      ] ++ modules;
    };

  mkNixos = { system, username, modules ? [], homeModules ? [] }:
    let
      home        = homeDir { inherit system username; };
      dotfilesDir = dotfilesDirOf { inherit system username; };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username dotfilesDir; };
      modules = [
        ../modules/nixos
        hm.nixosModules.home-manager
        { home-manager = {
            useGlobalPkgs   = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username dotfilesDir; };
            users.${username}.imports =
              [ (coreModule { inherit system username; }) ./dotlink.nix ../modules/home ]
              ++ homeModules;
          };
        }
      ] ++ modules;
    };

  mkDarwin = { system, username, modules ? [], homeModules ? [] }:
    let
      home        = homeDir { inherit system username; };
      dotfilesDir = dotfilesDirOf { inherit system username; };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username dotfilesDir; };
      modules = [
        ../modules/darwin
        hm.darwinModules.home-manager
        { home-manager = {
            useGlobalPkgs   = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username dotfilesDir; };
            users.${username}.imports =
              [ (coreModule { inherit system username; }) ./dotlink.nix ../modules/home ]
              ++ homeModules;
          };
        }
      ] ++ modules;
    };
}
