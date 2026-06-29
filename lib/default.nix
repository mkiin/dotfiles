inputs:
let
  inherit (inputs.nixpkgs) lib;

  homeDirOf =
    system: username:
    if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

  dotfilesDirOf =
    system: username: "${homeDirOf system username}/ghq/github.com/${username}/dotfiles";

  defaultOverlays = [
    # unstable の cantarell-fonts 0.311 は上流で otfautohint がビルド失敗し、かつ
    # バイナリキャッシュにも無い（steam-run の FHS 環境が間接的に引き込む）。
    # キャッシュ済みで動作する stable 版 (0.303.1) にピン留めして switch ブロックを回避する。
    # 上流修正/キャッシュ復旧後に削除してよい。
    (_final: prev: {
      inherit
        (
          (import inputs.nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          })
        )
        cantarell-fonts
        ;
    })
  ];

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = defaultOverlays;
    };

  mkStable =
    system:
    import inputs.nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };

  mkLnk =
    pkgs: dotfilesDir: path:
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
    {
      system,
      username,
      modules,
    }:
    let
      pkgs = mkPkgs system;
      pkgs-stable = mkStable system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          inputs
          system
          username
          pkgs-stable
          ;
        homeDirectory = homeDirOf system username;
        lnk = mkLnk pkgs dotfilesDir;
      };
      modules = [ (homeBase system username) ] ++ modules;
    };

  makeNixosConfig =
    {
      system,
      hostname,
      username,
      modules,
    }:
    let
      pkgs = mkPkgs system;
      pkgs-stable = mkStable system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          system
          username
          hostname
          pkgs-stable
          ;
        homeDirectory = homeDirOf system username;
      };
      modules = [
        {
          nixpkgs.pkgs = pkgs;
          networking.hostName = hostname;
        }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hmbak";
          home-manager.extraSpecialArgs = {
            inherit
              inputs
              system
              username
              pkgs-stable
              ;
            homeDirectory = homeDirOf system username;
            lnk = mkLnk pkgs dotfilesDir;
          };
          home-manager.users.${username} = homeBase system username;
        }
      ]
      ++ modules;
    };
}
