# NixOS flake 再構成 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** mkiin の dotfiles を、独自 `mkHome` 抽象と散在した設定ファイルから、`lib` 集約 + レイヤー分離 + コロケーションの flake 構成へ移行し、NixOS 実機で CachyOS 時代の Hyprland デスクトップを再現する。

**Architecture:** トップレベルを `lib/`（make*Config と `lnk` ヘルパーを集約）、`nixos/`（システム実設定）、`home-manager/`（home 実設定）、`hosts/`（マシン配線）に分ける。NixOS 実機は home-manager をシステムに統合し、WSL は standalone `homeConfigurations` に分ける。生設定ファイルは各ツールディレクトリに `.nix` と同居させ、`lnk ./path` で作業ツリーへの out-of-store symlink を張って hot-reload を維持する。

**Tech Stack:** Nix flakes, home-manager, NixOS 26.05, nixpkgs nixos-unstable, Hyprland (flake), NVIDIA (open kernel module), SDDM, fcitx5-mozc。

## Global Constraints

- 編集対象は Nix ソースのみ。`~` 配下の live ファイルを直接編集しない（`lnk` でリンクした作業ツリー上のソースを編集するのは可）。
- home の `home.stateVersion = "25.11"`（既存値を維持。安易に上げない）。
- システムの `system.stateVersion = "26.05"`（既存値を維持）。
- NVIDIA は Blackwell 世代のため `hardware.nvidia.open = true` 必須。
- `nixpkgs.config.allowUnfree = true`（discord, steam, nvidia, zen のため）。
- output 名：`nixosConfigurations.nixos` と `homeConfigurations."mkiin@wsl"`。
- ヘルパー名は `lnk`（旧 `dotLink` を廃止）。`lnk` は単一のコロケーションパスを取る（`lnk ./lua`）。
- 1 タスクごとに `git commit`。各フェーズ末で flake が評価・ビルドできること。
- 旧 `nix/` ツリーは全フェーズ完了まで残し、最後にまとめて削除する（途中で参照が壊れないように）。

---

## フェーズ構成と検証マイルストーン

- **Phase 0**：新トップレベルの足場 + `lib/` + `flake.nix` 骨格。検証：`nix flake check` が通る。
- **Phase 1**：現 home-manager（cli / editor / ai）を `home-manager/` へ移設し `lnk` 化。検証：`nix build .#homeConfigurations."mkiin@wsl".activationPackage`。
- **Phase 2**：NixOS システム層（core / hardware / nvidia / desktop 有効化 / sddm / audio / ime）+ `hosts/nixos` + mise 修正。検証：`nixos-rebuild switch` 後に SDDM が起動し、mise で node が入る。
- **Phase 3**：home デスクトップ層（hypr / waybar / quickshell / wlogout / matugen / wallust / mouse / fcitx5(user) / terminal）を `lnk ./` で移設。検証：再起動で Hyprland デスクトップが再現する。
- **Phase 4**：`nixos/apps`（discord / zen / steam / docker / 周辺機器 / ゲームランチャー）。検証：各アプリ起動。
- **Phase 5**：cachyos / 旧 `nix/` / `packages/` / `hooks/` / cachyos 用 script を削除し、docs を更新。検証：`nix flake check` と `nixos-rebuild build` が通る。

---

## Phase 0: 足場と lib

### Task 0.1: 作業ブランチと新トップレベルディレクトリ

**Files:**
- Create: `lib/`, `nixos/`, `home-manager/`, `hosts/nixos/`, `hosts/wsl/`（空ディレクトリは `.gitkeep` で確保）

- [ ] **Step 1: ブランチを切る**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
git switch -c restructure-flake
```

- [ ] **Step 2: 新ディレクトリを作る**

```bash
mkdir -p lib nixos/core nixos/hardware nixos/desktop nixos/apps \
  home-manager/cli home-manager/editor home-manager/ai home-manager/desktop \
  hosts/nixos hosts/wsl
```

- [ ] **Step 3: コミット**

```bash
git add -A && git commit -m "chore: scaffold new flake top-level layout"
```

### Task 0.2: lib/default.nix（make*Config と lnk を集約）

**Files:**
- Create: `lib/default.nix`

**Interfaces:**
- Produces:
  - `makeNixosConfig = { system, hostname, username, modules }: <nixosSystem>`
  - `makeHomeManagerConfig = { system, username, modules }: <homeManagerConfiguration>`
  - extraSpecialArgs / specialArgs で下流へ流す値：`inputs`, `system`, `username`, `homeDirectory`, `pkgs-stable`, `lnk`（home のみ）。

- [ ] **Step 1: lib/default.nix を書く**

```nix
inputs:
let
  inherit (inputs.nixpkgs) lib;

  homeDirOf = system: username:
    if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

  dotfilesDirOf = system: username:
    "${homeDirOf system username}/ghq/github.com/${username}/dotfiles";

  # 自作パッケージ等を足す場所。今は空。
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

  # コロケーションされたパス (例: ./lua) を作業ツリーの絶対パスに変換し、
  # out-of-store symlink を張る。switch 不要で編集が反映される。
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
    home.homeDirectory = homeDirOf system username;
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
in
{
  makeHomeManagerConfig =
    { system, username, modules }:
    let
      pkgs = mkPkgs system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs system username;
        homeDirectory = homeDirOf system username;
        pkgs-stable = mkStable system;
        lnk = mkLnk pkgs dotfilesDir;
      };
      modules = [ (homeBase system username) ] ++ modules;
    };

  makeNixosConfig =
    { system, hostname, username, modules }:
    let
      pkgs = mkPkgs system;
      dotfilesDir = dotfilesDirOf system username;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs system username hostname;
        homeDirectory = homeDirOf system username;
        pkgs-stable = mkStable system;
      };
      modules = [
        { nixpkgs.pkgs = pkgs; networking.hostName = hostname; }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs system username;
            homeDirectory = homeDirOf system username;
            pkgs-stable = mkStable system;
            lnk = mkLnk pkgs dotfilesDir;
          };
          home-manager.users.${username} = homeBase system username;
        }
      ] ++ modules;
    };
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/default.nix && git commit -m "feat(lib): add make*Config helpers and lnk"
```

### Task 0.3: flake.nix 骨格（inputs 追加 + outputs 切替）

**Files:**
- Modify: `flake.nix`

**Interfaces:**
- Consumes: `lib/default.nix`（`mylib.makeNixosConfig` / `makeHomeManagerConfig`）。
- Produces: `nixosConfigurations.nixos`, `homeConfigurations."mkiin@wsl"`。

- [ ] **Step 1: flake.nix を書き換える**

```nix
{
  description = "NixOS & home-manager configuration of mkiin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    hyprland.url = "github:hyprwm/Hyprland";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    xremap.url = "github:xremap/nix-flake";
    xremap.inputs.nixpkgs.follows = "nixpkgs";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";
    agent-skills.inputs.home-manager.follows = "home-manager";

    superpowers-skill = { url = "github:obra/superpowers"; flake = false; };
    cloudflare-skills = { url = "github:cloudflare/skills"; flake = false; };
    anthropic-skills = { url = "github:anthropics/skills"; flake = false; };
  };

  outputs =
    { self, ... }@inputs:
    let
      mylib = import ./lib inputs;
    in
    {
      nixosConfigurations.nixos = mylib.makeNixosConfig {
        system = "x86_64-linux";
        hostname = "nixos";
        username = "mkiin";
        modules = [ ./hosts/nixos ];
      };

      homeConfigurations."mkiin@wsl" = mylib.makeHomeManagerConfig {
        system = "x86_64-linux";
        username = "mkiin";
        modules = [ ./hosts/wsl/home-manager.nix ];
      };
    };
}
```

- [ ] **Step 2: 最小の host を置いて評価を通す**

`hosts/nixos/default.nix`:

```nix
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];
  system.stateVersion = "26.05";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

`hosts/wsl/home-manager.nix`:

```nix
{ ... }:
{ }
```

- [ ] **Step 3: hardware-configuration を取り込む**

```bash
sudo cp /etc/nixos/hardware-configuration.nix hosts/nixos/hardware-configuration.nix
sudo chown mkiin:users hosts/nixos/hardware-configuration.nix
```

- [ ] **Step 4: flake.lock を更新し評価する**

Run: `nix flake check`
Expected: エラーなく評価完了（warning は可）。失敗時はメッセージに従い修正。

- [ ] **Step 5: コミット**

```bash
git add flake.nix flake.lock hosts && git commit -m "feat(flake): switch to nixosConfigurations + homeConfigurations with new lib"
```

---

## Phase 1: home-manager 層の移設（cli / editor / ai）

> 既存の動く home 設定を `home-manager/` へ lift-and-shift する。各ツールは `.nix` と生ファイルを同居させ、`dotLink "sub" "name"` の呼び出しを `lnk ./name` に置換する。旧 `nix/modules/home/` は残したまま新側を作り、Phase 5 で旧側を消す。

### Task 1.1: home-manager/default.nix（base パッケージと共通設定）

**Files:**
- Create: `home-manager/default.nix`
- Source: `nix/modules/home/default.nix`, `nix/modules/home/packages.nix`

- [ ] **Step 1: home-manager/default.nix を書く**

```nix
{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./cli
    ./editor
    ./ai
  ];

  news.display = "silent";
}
```

- [ ] **Step 2: cli/editor/ai それぞれに集約 default.nix を置く**

`home-manager/cli/default.nix`:

```nix
{ ... }:
{
  imports = [
    ./packages.nix
    ./zsh
    ./git
    ./mise
    ./lazygit
    ./starship
    ./sheldon
    ./yazi
    ./goclipboard
    ./python
  ];
}
```

`home-manager/editor/default.nix`:

```nix
{ ... }:
{ imports = [ ./neovim ]; }
```

`home-manager/ai/default.nix`:

```nix
{ ... }:
{ imports = [ ./agent-skills ./claude-code ./codex ]; }
```

- [ ] **Step 3: packages.nix を移す**

```bash
git mv nix/modules/home/packages.nix home-manager/cli/packages.nix
```

- [ ] **Step 4: コミット**

```bash
git add home-manager && git commit -m "feat(home): add cli/editor/ai aggregators"
```

### Task 1.2: CLI ツールの移設（zsh, git, mise, lazygit, starship, sheldon, yazi, goclipboard, python）

各ツールについて、`<tool>.nix` を `home-manager/cli/<tool>/default.nix` に移し、付随する生ファイルを同ディレクトリへ移し、`dotLink` 呼び出しを `lnk ./...` に直す。

**ファイル対応:**

| 旧 .nix | 旧 生ファイル | 新ディレクトリ |
|---|---|---|
| `nix/modules/home/programs/zsh.nix` | `nix/modules/home/programs/zsh/functions.zsh`, `zsh/{zshrc,zshenv}` | `home-manager/cli/zsh/` |
| `git.nix` | なし | `home-manager/cli/git/` |
| `mise.nix` | `mise/config.toml` | `home-manager/cli/mise/` |
| `lazygit.nix` | なし | `home-manager/cli/lazygit/` |
| `starship.nix` | なし | `home-manager/cli/starship/` |
| `sheldon.nix` | なし | `home-manager/cli/sheldon/` |
| `yazi.nix` | なし | `home-manager/cli/yazi/` |
| `goclipboard.nix` | なし | `home-manager/cli/goclipboard/` |
| `python.nix` | なし | `home-manager/cli/python/` |

**`dotLink` → `lnk` 置換の型**（mise を例に、全ツール同じ要領）:

- [ ] **Step 1: ファイルを移す（mise の例）**

```bash
mkdir -p home-manager/cli/mise
git mv nix/modules/home/programs/mise.nix home-manager/cli/mise/default.nix
git mv mise/config.toml home-manager/cli/mise/config.toml
```

- [ ] **Step 2: 呼び出しを書き換える（mise の例）**

`home-manager/cli/mise/default.nix`:

```nix
{ pkgs, lnk, ... }:
{
  home.packages = [ pkgs.mise ];
  xdg.configFile."mise/config.toml".source = lnk ./config.toml;
}
```

- [ ] **Step 3: 残りの CLI ツールを同じ要領で移す**

zsh の例（生ファイルが複数）:

```bash
mkdir -p home-manager/cli/zsh
git mv nix/modules/home/programs/zsh.nix home-manager/cli/zsh/default.nix
git mv nix/modules/home/programs/zsh/functions.zsh home-manager/cli/zsh/functions.zsh
git mv zsh/zshrc home-manager/cli/zsh/zshrc
git mv zsh/zshenv home-manager/cli/zsh/zshenv
```

zsh の `default.nix` 内の `dotLink "zsh" "functions.zsh"` 等の参照を `lnk ./functions.zsh` 形式に直す。生ファイルを持たない git/lazygit/starship/sheldon/yazi/goclipboard/python は `git mv <tool>.nix home-manager/cli/<tool>/default.nix` のみ。

- [ ] **Step 4: 各ツール移設ごとにコミット**

```bash
git add -A && git commit -m "refactor(home): move <tool> to home-manager/cli/<tool> with lnk"
```

### Task 1.3: editor / ai の移設

- [ ] **Step 1: neovim を移す**

```bash
mkdir -p home-manager/editor/neovim
git mv nix/modules/home/programs/neovim.nix home-manager/editor/neovim/default.nix
git mv nvim home-manager/editor/neovim/config   # init.lua, lua/, after/ 等
```

neovim の `default.nix` で nvim 設定を symlink している箇所を `lnk ./config` に直す。

- [ ] **Step 2: ai ツールを移す**

```bash
mkdir -p home-manager/ai/{claude-code,codex,agent-skills}
git mv nix/modules/home/programs/claude-code.nix home-manager/ai/claude-code/default.nix
git mv nix/modules/home/programs/codex.nix       home-manager/ai/codex/default.nix
git mv nix/modules/home/agent-skills.nix         home-manager/ai/agent-skills/default.nix
git mv claude  home-manager/ai/claude-code/files
git mv codex   home-manager/ai/codex/files
git mv agents  home-manager/ai/agent-skills/files
```

各 `default.nix` 内の参照パス（`claude/`, `codex/`, `agents/skills/`）を新パスへ更新。`dotLink`/`builtins.readFile`/`.source` を `lnk ./files/...` または相対 `./files/...` に直す。

- [ ] **Step 3: WSL host が cli を読むよう配線**

`hosts/wsl/home-manager.nix`:

```nix
{ lib, pkgs, ... }:
{
  imports = [ ../../home-manager/cli ];

  home.packages = with pkgs; [ unzip zip ];

  programs.zsh.shellAliases.open = "explorer.exe .";
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -n "''${WSL_DISTRO_NAME:-}" && "$PWD" == /mnt/[a-zA-Z]/* ]]; then
      cd "$HOME"
    fi
  '';
}
```

- [ ] **Step 4: ビルド検証**

Run: `nix build .#homeConfigurations."mkiin@wsl".activationPackage`
Expected: ビルド成功。失敗時は未解決パス / 未定義引数を修正。

- [ ] **Step 5: コミット**

```bash
git add -A && git commit -m "refactor(home): move editor/ai and wire wsl host"
```

---

## Phase 2: NixOS システム層と mise 修正

> ここから実機システムを変更する。各タスクは `nixos-rebuild build`（switch しないビルド確認）を挟む。Hyprland の起動には Phase 3 の home 設定も要るが、Phase 2 末で SDDM ログイン画面までは到達する。

### Task 2.1: nixos/core 層

**Files:**
- Create: `nixos/core/{boot.nix,nix.nix,users.nix,locale.nix,time.nix,network.nix,shell.nix,nix-ld.nix}`
- Create: `nixos/default.nix`
- Source: `/etc/nixos/configuration.nix`

- [ ] **Step 1: nixos/default.nix（集約）**

```nix
{ ... }:
{
  imports = [
    ./core/boot.nix
    ./core/nix.nix
    ./core/users.nix
    ./core/locale.nix
    ./core/time.nix
    ./core/network.nix
    ./core/shell.nix
    ./core/nix-ld.nix
    ./hardware
    ./desktop
  ];
}
```

- [ ] **Step 2: core 各ファイルを書く**

`nixos/core/boot.nix`:

```nix
{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

`nixos/core/nix.nix`:

```nix
{ ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = { automatic = true; options = "--delete-older-than 14d"; };
  nixpkgs.config.allowUnfree = true;
}
```

`nixos/core/users.nix`:

```nix
{ pkgs, username, ... }:
{
  programs.zsh.enable = true;
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
  };
}
```

`nixos/core/locale.nix`:

```nix
{ pkgs, ... }:
{
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8"; LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8"; LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8"; LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8"; LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };
}
```

`nixos/core/time.nix`:

```nix
{ ... }:
{ time.timeZone = "Asia/Tokyo"; }
```

`nixos/core/network.nix`:

```nix
{ ... }:
{ networking.networkmanager.enable = true; }
```

`nixos/core/shell.nix`:

```nix
{ ... }:
{ }
```

`nixos/core/nix-ld.nix`（mise のための土台。ライブラリは Task 2.6 で追加）:

```nix
{ ... }:
{ programs.nix-ld.enable = true; }
```

- [ ] **Step 3: host から nixos/ を読む**

`hosts/nixos/default.nix` を更新:

```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];
  system.stateVersion = "26.05";
}
```

- [ ] **Step 4: ビルド検証**

Run: `sudo nixos-rebuild build --flake .#nixos`
Expected: ビルド成功。

- [ ] **Step 5: コミット**

```bash
git add nixos hosts && git commit -m "feat(nixos): core layer"
```

### Task 2.2: nixos/hardware（graphics, nvidia, bluetooth）

**Files:**
- Create: `nixos/hardware/{default.nix,nvidia.nix,bluetooth.nix}`

**重要（調査ステップ）:** Blackwell (RTX 5070 Ti) 対応ドライバ版を確定する。

- [ ] **Step 1: nixos/hardware/default.nix**

```nix
{ ... }:
{
  imports = [ ./nvidia.nix ./bluetooth.nix ];
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
```

- [ ] **Step 2: nvidia ドライバ版を調査する**

```bash
nix eval --raw nixpkgs#linuxKernel.packages.linux_latest.nvidiaPackages.stable.version
nix eval --raw nixpkgs#linuxKernel.packages.linux_latest.nvidiaPackages.beta.version
```

Expected: `stable` が 570 系以上なら Blackwell 対応。未満なら `beta`/`production` を確認して採用版を決める。

- [ ] **Step 3: nixos/hardware/nvidia.nix**

```nix
{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;                 # Blackwell 必須
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;  # Step 2 の結果で beta 等に変更
  };
}
```

- [ ] **Step 4: nixos/hardware/bluetooth.nix**

```nix
{ ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
```

- [ ] **Step 5: ビルド検証**

Run: `sudo nixos-rebuild build --flake .#nixos`
Expected: ビルド成功。

- [ ] **Step 6: コミット**

```bash
git add nixos/hardware && git commit -m "feat(nixos): nvidia(open)+graphics+bluetooth"
```

### Task 2.3: nixos/desktop（hyprland 有効化, sddm, fcitx5, sound, polkit）

**Files:**
- Create: `nixos/desktop/{default.nix,hyprland.nix,display-manager.nix,fcitx5.nix,sound.nix,polkit.nix}`

- [ ] **Step 1: nixos/desktop/default.nix**

```nix
{ ... }:
{
  imports = [
    ./hyprland.nix
    ./display-manager.nix
    ./fcitx5.nix
    ./sound.nix
    ./polkit.nix
  ];
}
```

- [ ] **Step 2: hyprland.nix（flake input のパッケージを使用）**

```nix
{ inputs, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
  programs.uwsm.enable = true;
  programs.dconf.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
```

- [ ] **Step 3: display-manager.nix（SDDM、theme は Phase 3 で配線）**

```nix
{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
}
```

- [ ] **Step 4: fcitx5.nix**

```nix
{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
  };
}
```

- [ ] **Step 5: sound.nix**

```nix
{ ... }:
{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
```

- [ ] **Step 6: polkit.nix**

```nix
{ pkgs, ... }:
{
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.kdePackages.polkit-kde-agent-1 ];
  security.pam.services.hyprlock = { };
}
```

- [ ] **Step 7: ビルド検証**

Run: `sudo nixos-rebuild build --flake .#nixos`
Expected: ビルド成功。

- [ ] **Step 8: コミット**

```bash
git add nixos/desktop && git commit -m "feat(nixos): desktop enable (hyprland/sddm/fcitx5/sound/polkit)"
```

### Task 2.4: nixos/core/fonts と nixos-hardware プロファイル

**Files:**
- Create: `nixos/core/fonts.nix`
- Modify: `hosts/nixos/default.nix`

- [ ] **Step 1: fonts.nix**

```nix
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-serif noto-fonts-cjk-sans noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono material-design-icons
  ];
  fonts.fontconfig.defaultFonts = {
    serif = [ "Noto Serif CJK JP" "Noto Color Emoji" ];
    sansSerif = [ "Noto Sans CJK JP" "Noto Color Emoji" ];
    monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
    emoji = [ "Noto Color Emoji" ];
  };
}
```

import を `nixos/default.nix` の core 群に追加する。

- [ ] **Step 2: host に nixos-hardware を足す**

`hosts/nixos/default.nix` の imports に AMD 共通プロファイルを追加:

```nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-ssd
```

- [ ] **Step 3: ビルド検証**

Run: `sudo nixos-rebuild build --flake .#nixos`
Expected: 成功。`common-gpu-nvidia` と自前 nvidia.nix の設定が衝突しないこと（衝突時は `lib.mkForce` か一方を削る）。

- [ ] **Step 4: コミット**

```bash
git add nixos hosts && git commit -m "feat(nixos): fonts + nixos-hardware profiles"
```

### Task 2.5: 初回 switch と SDDM 起動確認

- [ ] **Step 1: switch する**

Run: `sudo nixos-rebuild switch --flake .#nixos`
Expected: 成功。`/etc/nixos` は使われず flake から構築される。

- [ ] **Step 2: 再起動して SDDM を確認**

```bash
sudo reboot
```

Expected: GDM ではなく SDDM のログイン画面が出る。ログイン後、セッションに Hyprland (uwsm) が選べる。

- [ ] **Step 3: 確認をコミット（変更があれば）**

```bash
git add -A && git commit -m "chore: first system switch verified (sddm up)"
```

### Task 2.6: mise の node/python インストール修正

**Files:**
- Modify: `nixos/core/nix-ld.nix`

- [ ] **Step 1: エラーを再現して原因を見る**

```bash
mise install node@24 2>&1 | tail -40
```

Expected: 実際のエラーメッセージを確認する（prebuilt の dynamic linker 不整合か、python 不在によるビルド失敗かを切り分ける）。

- [ ] **Step 2: 切り分けに応じて対処する**

prebuilt のリンカ問題なら `programs.nix-ld.libraries` を補強する:

```nix
{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc zlib openssl
  ];
}
```

node のビルドに python が要る経路なら、mise の node を prebuilt に固定する（`mise settings set node.compile false`）か、`home-manager/cli/mise` の環境で python を提供する。Step 1 のエラー実物を見て確定する。

- [ ] **Step 3: 適用して検証**

Run: `sudo nixos-rebuild switch --flake .#nixos && mise install node@24 && node --version`
Expected: node のバージョンが表示される。python も同様に確認。

- [ ] **Step 4: コミット**

```bash
git add nixos/core/nix-ld.nix && git commit -m "fix(nixos): nix-ld libraries for mise prebuilt runtimes"
```

---

## Phase 3: home デスクトップ層の移設

> Wayland デスクトップの設定本体を `home-manager/desktop/` に移し、`lnk ./` で配布する。実機 host から desktop 層を読み込み、再起動して Hyprland 環境を再現する。

### Task 3.1: hyprland（lnk ./ への移行の代表例）

**Files:**
- Create: `home-manager/desktop/hyprland/default.nix`
- Source: `nix/modules/linux/desktop/hyprland/default.nix`, `nix/modules/linux/desktop/hyprland/monitor.nix`, `hypr/`

- [ ] **Step 1: ファイルを移す**

```bash
mkdir -p home-manager/desktop/hyprland
git mv nix/modules/linux/desktop/hyprland/default.nix home-manager/desktop/hyprland/default.nix
git mv nix/modules/linux/desktop/hyprland/monitor.nix home-manager/desktop/hyprland/monitor.nix
git mv hypr/lua            home-manager/desktop/hyprland/lua
git mv hypr/monitors       home-manager/desktop/hyprland/monitors
git mv hypr/scripts        home-manager/desktop/hyprland/scripts
git mv hypr/hyprlock.conf  home-manager/desktop/hyprland/hyprlock.conf
```

- [ ] **Step 2: default.nix を lnk ./ で書き直す**

```nix
{ inputs, pkgs, lnk, ... }:
{
  imports = [ ./monitor.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = null;
    xwayland.enable = true;
    systemd.enable = false;
    configType = "lua";
  };

  xdg.configFile = {
    "hypr/hyprland.lua".source     = lnk ./lua/hyprland.lua;
    "hypr/vars.lua".source         = lnk ./lua/vars.lua;
    "hypr/color-scheme.lua".source = lnk ./lua/color-scheme.lua;
    "hypr/appearance.lua".source   = lnk ./lua/appearance.lua;
    "hypr/input.lua".source        = lnk ./lua/input.lua;
    "hypr/autostart.lua".source    = lnk ./lua/autostart.lua;
    "hypr/keybinds.lua".source     = lnk ./lua/keybinds.lua;
    "hypr/rules.lua".source        = lnk ./lua/rules.lua;
    "hypr/scripts".source          = lnk ./scripts;
    "hypr/hyprlock.conf".source    = lnk ./hyprlock.conf;
  };
}
```

`monitor.nix` 内の `dotLink "hypr/monitors" ...` も `lnk ./monitors/...` に直す。

- [ ] **Step 3: コミット**

```bash
git add -A && git commit -m "refactor(home): move hyprland to home-manager/desktop with lnk"
```

### Task 3.2: 残りの desktop ツール（同じ lnk ./ パターン）

Task 3.1 と同じ要領で移す。生ファイルを `home-manager/desktop/<tool>/` に置き、`dotLink "<sub>" "<name>"` を `lnk ./<name>` に直す。

**ファイル対応:**

| 旧 .nix | 旧 生ファイル | 新ディレクトリ |
|---|---|---|
| `nix/modules/linux/desktop/waybar.nix` | `waybar/` | `home-manager/desktop/waybar/` |
| `quickshell.nix` | `quickshell/` | `home-manager/desktop/quickshell/` |
| `wlogout.nix` | `wlogout/` | `home-manager/desktop/wlogout/` |
| `fcitx5.nix` | `fcitx5/` | `home-manager/desktop/fcitx5/` |
| `mouse.nix` | `mouse/` | `home-manager/desktop/mouse/` |
| `services.nix` | なし | `home-manager/desktop/services/` |
| `../programs/matugen.nix` | `matugen/` | `home-manager/desktop/matugen/` |
| `../programs/wallust.nix` | `wallust/` | `home-manager/desktop/wallust/` |
| `../programs/ghostty.nix` | なし | `home-manager/desktop/terminal/ghostty/` |
| `../programs/wezterm.nix` | `wezterm/` | `home-manager/desktop/terminal/wezterm/` |

- [ ] **Step 1: 各ツールを移して lnk 化（waybar の例）**

```bash
mkdir -p home-manager/desktop/waybar
git mv nix/modules/linux/desktop/waybar.nix home-manager/desktop/waybar/default.nix
git mv waybar/config.jsonc waybar/style.css waybar/scripts waybar/styles home-manager/desktop/waybar/
```

`default.nix` の symlink を `lnk ./config.jsonc` 等に直す。

- [ ] **Step 2: desktop 集約 default.nix を書く**

`home-manager/desktop/default.nix`:

```nix
{ lib, ... }:
{
  imports = [
    ./hyprland
    ./waybar
    ./quickshell
    ./wlogout
    ./fcitx5
    ./mouse
    ./services
    ./matugen
    ./wallust
    ./terminal/ghostty
    ./terminal/wezterm
  ];

  programs.zsh = {
    shellAliases.qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    initContent = lib.mkAfter ''
      abbr wbr="pkill -x waybar; uwsm app -- waybar &>/dev/null & disown"
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/claude-cli"   = "claude-code-url-handler.desktop";
      "x-scheme-handler/http"         = "zen.desktop";
      "x-scheme-handler/https"        = "zen.desktop";
      "text/html"                     = "zen.desktop";
      "video/mp4"                     = "mpv.desktop";
    };
  };
}
```

- [ ] **Step 3: 実機 host から home desktop を読む**

`hosts/nixos/default.nix` に home-manager の imports を追加:

```nix
  home-manager.users.mkiin.imports = [
    ../../home-manager
    ../../home-manager/desktop
  ];
```

（`../../home-manager` は cli/editor/ai を読む。desktop は実機のみ追加。）

- [ ] **Step 4: ビルド検証**

Run: `sudo nixos-rebuild build --flake .#nixos`
Expected: 成功。未解決の `lnk` パスや旧 `dotLink` 残りを潰す。

- [ ] **Step 5: switch して再起動**

```bash
sudo nixos-rebuild switch --flake .#nixos && sudo reboot
```

Expected: SDDM → Hyprland セッションで、waybar / quickshell / 壁紙 / キーバインドが CachyOS 時代どおり動く。

- [ ] **Step 6: コミット**

```bash
git add -A && git commit -m "refactor(home): move all desktop tools to home-manager/desktop with lnk"
```

---

## Phase 4: nixos/apps（GUI アプリと周辺機器）

> `packages/pacman.txt` と `packages/yay.txt` の手動導入分を、system 層の宣言に移す。

### Task 4.1: GUI アプリと開発基盤

**Files:**
- Create: `nixos/apps/{default.nix,steam.nix,docker.nix,desktop-apps.nix,peripherals.nix}`

- [ ] **Step 1: nixos/apps/default.nix**

```nix
{ ... }:
{ imports = [ ./steam.nix ./docker.nix ./desktop-apps.nix ./peripherals.nix ]; }
```

- [ ] **Step 2: steam.nix**

```nix
{ ... }:
{ programs.steam.enable = true; }
```

- [ ] **Step 3: docker.nix**

```nix
{ ... }:
{
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
}
```

- [ ] **Step 4: desktop-apps.nix（本体だけの GUI アプリ）**

```nix
{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    pkgs.discord
    pkgs.upscayl
    pkgs.guvcview
    pkgs.gpu-screen-recorder
    pkgs.wl-clipboard
    inputs.zen-browser.packages.${pkgs.system}.default
  ];
}
```

- [ ] **Step 5: peripherals.nix**

```nix
{ pkgs, ... }:
{
  services.ratbagd.enable = true;          # piper backend
  environment.systemPackages = [ pkgs.piper pkgs.solaar pkgs.via ];
}
```

- [ ] **Step 6: nixos/default.nix に apps を追加し switch**

Run: `sudo nixos-rebuild switch --flake .#nixos`
Expected: 成功。discord / zen / steam が起動する。

- [ ] **Step 7: コミット**

```bash
git add nixos/apps nixos/default.nix && git commit -m "feat(nixos): apps (steam/docker/discord/zen/peripherals)"
```

### Task 4.2: ゲームランチャーと未提供パッケージ

- [ ] **Step 1: nixpkgs 提供状況を確認**

```bash
nix search nixpkgs anime-game-launcher
nix search nixpkgs honkers
```

Expected: 提供がなければ `aagl` 等の flake input 追加か、当面保留と判断する。`local/bin/nikke-launch.sh` と `local/share/icons/` は `home-manager/desktop` の `home.file` で配る。

- [ ] **Step 2: nikke ランチャーを home へ移す**

```bash
git mv local home-manager/desktop/launchers
```

`home-manager/desktop/default.nix` に desktop entry とアイコンの配置を `lnk`/`home.file` で追加。

- [ ] **Step 3: コミット**

```bash
git add -A && git commit -m "feat(home): game launchers and custom desktop entries"
```

---

## Phase 5: 旧構成の削除と docs 更新

### Task 5.1: 旧ツリーと cachyos の削除

- [ ] **Step 1: 旧 nix/ と cachyos を消す**

```bash
git rm -r nix
git rm -r packages hooks
git rm scripts/bootstrap-cachyos.sh scripts/sync-packages.sh scripts/sync-packages-apt.sh
```

- [ ] **Step 2: 残った参照を確認**

```bash
nix flake check
```

Expected: 旧 `nix/` への参照が残っていればエラーになるので潰す。

- [ ] **Step 3: コミット**

```bash
git add -A && git commit -m "chore: remove legacy nix/ tree, cachyos host, package snapshots"
```

### Task 5.2: docs 更新

**Files:**
- Modify: `docs/nix-folder-structure.md`
- Modify: `README.md`

- [ ] **Step 1: フォルダ構成ドキュメントを新構造に合わせて書き換える**

`lib/`・`nixos/`・`home-manager/`・`hosts/` の責務と、`lnk ./` の使い方、フォルダ分けルール（レイヤー第1軸、home は cli/editor/ai/desktop、ツール=1ディレクトリでコロケーション）を記述する。

- [ ] **Step 2: README に switch コマンドを記載**

```bash
sudo nixos-rebuild switch --flake .#nixos      # 実機
home-manager switch --flake .#"mkiin@wsl"      # WSL
```

- [ ] **Step 3: 最終検証**

Run: `nix flake check && sudo nixos-rebuild build --flake .#nixos`
Expected: 両方成功。

- [ ] **Step 4: コミット and マージ**

```bash
git add -A && git commit -m "docs: update folder structure and switch commands"
git switch main && git merge --no-ff restructure-flake
```

---

## Self-Review

- **Spec coverage:** いけてないディレクトリ分離の見直し（Phase 0,1,3 の新構造）、コロケーション（`lnk ./` 化）、デスクトップ再現（Phase 2,3,4）、mise 修正（Task 2.6）、mkHome 廃止と lib 整理（Task 0.2）、フォルダ分けルール明文化（Task 5.2）、cachyos 除去（Task 5.1）を網羅。
- **未確定で調査ステップに委ねた点:** NVIDIA ドライバ版（Task 2.2 Step 2）、mise エラーの実体（Task 2.6 Step 1）、ゲームランチャーの nixpkgs 提供（Task 4.2 Step 1）。いずれも実機でコマンド実行 → 結果に応じて分岐、と明示。
- **命名一貫性:** ヘルパーは全タスクで `lnk`、output は `nixosConfigurations.nixos` と `homeConfigurations."mkiin@wsl"` で統一。

## 既知のリスクと注意

- `common-gpu-nvidia`（nixos-hardware）と自前 `nvidia.nix` の設定衝突（Task 2.4 Step 3 で確認）。
- `home.stateVersion`（25.11）と `system.stateVersion`（26.05）の取り違え禁止。
- Hyprland を flake input と nixpkgs で二重に入れない（system/home とも flake input の package に向ける）。
- `lnk` は作業ツリー（`~/ghq/github.com/mkiin/dotfiles`）から `--flake .#` で適用する前提。別パスから適用するとリンク先が存在しなくなる。
