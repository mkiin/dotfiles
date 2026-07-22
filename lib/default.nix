inputs:
let
  inherit (inputs.nixpkgs) lib;

  homeDirOf =
    system: username:
    if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

  dotfilesDirOf =
    system: username: "${homeDirOf system username}/ghq/github.com/${username}/dotfiles";

  defaultOverlays = [
    # claude-code / codex を numtide/llm-agents.nix（日次更新・prebuilt）から供給する。
    inputs.llm-agents.overlays.shared-nixpkgs

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

    # noto-fonts-cjk の可変フォント版(VF ttc)は Firefox 系で太字(600 前後)の
    # 欧文の送り幅が壊れて字が重なる。fonts.enableDefaultPackages も素の
    # パッケージを引き込むため、overlay で全域を静的版に差し替える。
    (_final: prev: {
      noto-fonts-cjk-sans = prev.noto-fonts-cjk-sans.override { static = true; };
      noto-fonts-cjk-serif = prev.noto-fonts-cjk-serif.override { static = true; };
    })
  ];

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      # vesktop がビルド時に引く pnpm。上流が修正版に上げたら削除する
      config.permittedInsecurePackages = [ "pnpm-10.29.2" ];
      overlays = defaultOverlays;
    };

  mkStable =
    system:
    import inputs.nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };

  # Nix パス = モジュール同階層のコロケーション参照。
  # 文字列 = 絶対パス（"''${dotfilesDir}/images/..." 等）。`../..` で遡る参照は書かない。
  mkLnk =
    pkgs: dotfilesDir: p:
    let
      target =
        if builtins.isPath p then
          dotfilesDir + lib.removePrefix (toString inputs.self) (toString p)
        else
          assert lib.assertMsg (lib.hasPrefix "/" p) "lnk: 文字列は絶対パスで渡す（\${dotfilesDir}/... を使う）";
          p;
    in
    pkgs.runCommandLocal (baseNameOf (toString p)) { } ''
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
          dotfilesDir
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
              dotfilesDir
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
