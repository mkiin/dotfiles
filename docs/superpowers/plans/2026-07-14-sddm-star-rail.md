# SDDM + qylock star-rail テーマ導入 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ログイン画面を greetd + regreet から SDDM（Wayland、Qt6）+ qylock star-rail テーマに置き換える。

**Architecture:** `nixos/desktop/sddm/` を新設し、テーマは fetchFromGitHub の rev 固定 derivation（`theme.nix`）で star-rail のみ取り込む。SDDM 設定は同ディレクトリの `default.nix` に置き、greetd ディレクトリは削除する。spec: `docs/superpowers/specs/2026-07-14-sddm-star-rail-design.md`

**Tech Stack:** NixOS module（services.displayManager.sddm）、stdenvNoCC derivation、kdePackages（Qt6）

## Global Constraints

- パッケージ宣言は集約 `packages.nix` のみ。ただし `extraPackages` / `programs.*.package` は設定機構なので可（CLAUDE.md）
- `../` で遡る相対パス参照は禁止
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止
- コミット前に `nix run .#build` と `nix run .#fmt -- --fail-on-change` を両方通す
- main への push は各タスク完了時点では行わない（CI フルビルドが遅いため、最後にまとめて）
- qylock の固定 rev: `db61a972b4b23728d9944a906e70029ca8a5899d`（2026-06-05 時点の HEAD）

---

### Task 1: SDDM への置き換え（theme.nix + default.nix + greetd 削除）

greetd と SDDM はどちらもディスプレイマネージャーなので共存できない。作成・差し替え・削除を 1 コミットで原子的に行う。

**Files:**

- Create: `nixos/desktop/sddm/theme.nix`
- Create: `nixos/desktop/sddm/default.nix`
- Modify: `nixos/desktop/default.nix`（imports の `./greetd` → `./sddm`）
- Delete: `nixos/desktop/greetd/`（default.nix, style.css）

**Interfaces:**

- Produces: `theme.nix` は `callPackage` 可能な derivation。出力は `$out/share/sddm/themes/star-rail/`（Main.qml, bg.mp4, theme.conf, metadata.desktop）。テーマ名 `"star-rail"` は `services.displayManager.sddm.theme` の値と一致していなければならない。

- [ ] **Step 1: theme.nix を作成（hash は空でスタート）**

`hash = ""` は意図的な仮置き。ビルドが hash mismatch で失敗し、エラーに正しい hash が表示される（Nix の定石）。

```nix
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "sddm-star-rail-theme";
  version = "0-unstable-2026-06-05";

  src = fetchFromGitHub {
    owner = "Darkkal44";
    repo = "qylock";
    rev = "db61a972b4b23728d9944a906e70029ca8a5899d";
    hash = "";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sddm/themes
    cp -r themes/star-rail $out/share/sddm/themes/star-rail
    runHook postInstall
  '';
}
```

- [ ] **Step 2: default.nix を作成**

```nix
{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "star-rail";
    # qt5compat/qtmultimedia/qtsvg はテーマの Main.qml が import する
    # QML モジュールを greeter プロセスへ供給するために必要
    extraPackages = with pkgs.kdePackages; [
      (pkgs.callPackage ./theme.nix { })
      qt5compat
      qtmultimedia
      qtsvg
    ];
  };
}
```

- [ ] **Step 3: nixos/desktop/default.nix の imports を差し替え**

```nix
{ ... }:
{
  imports = [
    ./hyprland
    ./sddm
    ./fcitx5
    ./sound
    ./polkit
    ./vesktop
    ./steam
    ./games/honkers
  ];
}
```

- [ ] **Step 4: greetd ディレクトリを削除**

```bash
git rm -r nixos/desktop/greetd
```

- [ ] **Step 5: ビルドして hash を確定**

Run: `nix run .#build`
Expected: `error: hash mismatch in fixed-output derivation` で失敗し、`got: sha256-...` に正しい hash が表示される。

その `sha256-...` を `theme.nix` の `hash = "";` に転記する。

- [ ] **Step 6: ビルドが通ることを確認**

Run: `nix run .#build`
Expected: 成功（警告なしで終了）。qylock の取得（動画込み）で初回は数分かかる。

- [ ] **Step 7: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで終了コード 0。失敗したら `nix run .#fmt` で整形して再確認。

- [ ] **Step 8: コミット**

```bash
git add nixos/desktop/sddm nixos/desktop/default.nix
git commit -m "feat(desktop): greetd+regreet を SDDM + star-rail テーマに置き換え"
```

（`git rm` 済みの greetd は staged になっている）

---

### Task 2: テーマ試写と実機反映

**Files:** 変更なし（検証のみ）

**Interfaces:**

- Consumes: Task 1 の `nixos/desktop/sddm/theme.nix`（callPackage 可能な derivation）

- [ ] **Step 1: テーマ単体を試写（任意・ベストエフォート）**

```bash
THEME=$(nix build --impure --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.nixos.pkgs.callPackage ./nixos/desktop/sddm/theme.nix { }' --no-link --print-out-paths)
nix shell nixpkgs#kdePackages.sddm -c sddm-greeter-qt6 --test-mode --theme "$THEME/share/sddm/themes/star-rail"
```

Expected: ウィンドウが開き、動画背景とパスワード欄が描画される。

注意: この試写環境では extraPackages の QML パス配線が無いため、`Qt5Compat` 等の import エラーで背景が出ないことがある。その場合も本番 greeter では extraPackages が効くので、失敗しても Step 2 に進んでよい（ここでの失敗はブロッカーではない）。

- [ ] **Step 2: 実機反映**

Run: `nix run .#switch`
Expected: 成功。sudo パスワードが要求される。

- [ ] **Step 3: 本番確認**

再起動（またはログアウト）して確認する:

1. SDDM のログイン画面に star-rail テーマ（動画背景）が表示される
2. パスワード入力で Hyprland セッションにログインできる
3. 電源・再起動ボタンが動作する（確認は表示まででよい）

既知のリスク（spec 記載）: NVIDIA + Wayland で動画背景だけ黒画面になる場合がある。その場合もログイン機能は動くので、発生したら別途対処を検討する。

- [ ] **Step 4: push**

確認が取れたら push する（CI は後追いの保険）:

```bash
git push
```
