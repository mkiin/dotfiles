inputs:
let
  inherit (inputs.nixpkgs) lib;

  homeDirOf = system: username:
    if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

  dotfilesDirOf = system: username:
    "${homeDirOf system username}/ghq/github.com/${username}/dotfiles";

  defaultOverlays = [ ];

  mkPkgs = system: import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = defaultOverlays;
  };

  mkStable = system: import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  mkLnk = pkgs: dotfilesDir: path:
    let
      rel = lib.removePrefix (toString inputs.self) (toString path);
      target = dotfilesDir + rel;
    in
    pkgs.runCommandLocal (builtins.baseNameOf (toString path)) { } ''
      ln -s ${lib.escapeShellArg target} $out
    '';

  homeBase = system: username: {
    home.username = username;
    home.homeDirectory = lib.mkForce (homeDirOf system username);
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
in
{
  makeHomeManagerConfig =
    { system, username, modules }:
    let
      pkgs = mkPkgs system;
      pkgs-stable = mkStable system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs system username pkgs-stable;
        homeDirectory = homeDirOf system username;
        lnk = mkLnk pkgs dotfilesDir;
      };
      modules = [ (homeBase system username) ] ++ modules;
    };

  makeNixosConfig =
    { system, hostname, username, modules }:
    let
      pkgs = mkPkgs system;
      pkgs-stable = mkStable system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs system username hostname pkgs-stable;
        homeDirectory = homeDirOf system username;
      };
      modules = [
        { nixpkgs.pkgs = pkgs; networking.hostName = hostname; }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hmbak";
          home-manager.extraSpecialArgs = {
            inherit inputs system username pkgs-stable;
            homeDirectory = homeDirOf system username;
            lnk = mkLnk pkgs dotfilesDir;
          };
          home-manager.users.${username} = homeBase system username;
        }
      ] ++ modules;
    };
}
