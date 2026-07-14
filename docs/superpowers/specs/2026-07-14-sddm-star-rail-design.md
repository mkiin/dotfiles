# SDDM + qylock star-rail テーマ導入の設計

## 目的

ログイン画面を greetd + regreet から SDDM（Wayland モード、Qt6）に置き換え、テーマに Darkkal44/qylock の `star-rail` を使う。
対象は実機 NixOS（`nixosConfigurations.nixos`）のみ。
WSL 構成はデスクトップを import しないため影響しない。

## 決定事項

- **テーマ**：qylock の `star-rail`（Main.qml + bg.mp4 の動画背景 + theme.conf、Qt6 ネイティブ）。
  独自テーマの自作は工数の観点で見送った。
- **取り込み方式**：qylock を flake input にはせず、`fetchFromGitHub` で rev 固定して取得する自前 derivation を書く。
  flake input にすると全 36 テーマ（動画込みで数百 MB）を Renovate の lock 更新のたびに再取得し、upstream の変更でテーマの見た目が勝手に変わりうるためである。
- **配置**：リポジトリのコロケーションルールに従い、derivation は `nixos/desktop/sddm/theme.nix` として設定と同じディレクトリに置く。
  `packages/` には callPackage の仕組みが無く、この derivation を他から参照する予定も無い。
- **ロック画面**：hyprlock + hypridle を維持する。qylock の quickshell-lockscreen は導入しない。

## 変更内容

### 削除

- `nixos/desktop/greetd/`（`default.nix` と `style.css`）。
  `services.greetd` と `programs.regreet` の設定はこのディレクトリにしか無い。
- regreet が参照していた `images/login/login.png` は削除しない（他用途で使う可能性があるため残す）。

### 新規: `nixos/desktop/sddm/theme.nix`

`stdenvNoCC` の derivation。

- `fetchFromGitHub` で Darkkal44/qylock を rev 固定で取得する（rev と hash は実装時に確定する）。
- `themes/star-rail/` だけを `$out/share/sddm/themes/star-rail/` にコピーする。
- ビルドもパッチも不要（`dontBuild`、install のみ）。

### 新規: `nixos/desktop/sddm/default.nix`

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
  package = pkgs.kdePackages.sddm;   # Qt6 greeter
  theme = "star-rail";
  extraPackages = with pkgs.kdePackages; [
    (pkgs.callPackage ./theme.nix { })
    qt5compat      # Main.qml が import する Qt5Compat.GraphicalEffects
    qtmultimedia   # bg.mp4 の動画背景
    qtsvg
  ];
};
```

`extraPackages` は greeter プロセスの QML import パスへ供給する正規の設定機構であり、パッケージ宣言の直書き禁止ルールには当たらない。

### 変更: `nixos/desktop/default.nix`

imports の `./greetd` を `./sddm` に差し替える。

## 検証

1. `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
2. 反映前にテーマ単体を試写する：
   `sddm-greeter-qt6 --test-mode --theme <theme.nix のビルド結果>/share/sddm/themes/star-rail`。
   動画背景の再生とパスワード欄の描画をウィンドウ内で確認できる。
3. `nix run .#switch` 後、再ログインで本番動作を確認する。

## リスク

- 動画背景のデコードは qtmultimedia の ffmpeg バックエンドに依存する。
  NVIDIA + Wayland の greeter 上で背景だけ黒画面になる報告があるが、その場合も SDDM のログイン機能自体は動く。
- greeter が Qt5 で起動すると `Qt5Compat` 等の import に失敗する。
  `metadata.desktop` の `QtVersion=6` と `pkgs.kdePackages.sddm`（Qt6 版）の明示で回避する。
