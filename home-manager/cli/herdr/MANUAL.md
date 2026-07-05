# herdr チュートリアルマニュアル

herdr は tmux を AI コーディングエージェント向けに作り直したターミナルマルチプレクサです。ワークスペース / タブ / ペインを持ち、各ペインは実ターミナルとして動きます。サイドバーが各エージェントの状態を 🔴 blocked / 🟡 working / 🔵 done / 🟢 idle で集約表示し、detach してもエージェントは生き続けます。

この dotfiles では Nix で導入済みです。`herdr` はそのまま PATH にあります。

## 1. 起動と最初の一歩

```bash
herdr
```

バックグラウンドサーバーを起動（または再接続）してワークスペースを開きます。開いたペインでエージェントを起動します。

```bash
claude
```

サイドバーにそのエージェントの状態が出ます。マウス操作にも対応していて、ペイン・タブ・分割境界はクリックとドラッグで操作できます。

## 2. プレフィックスの考え方

herdr はプレフィックス方式です。まず `ctrl+b` を押して離し、続けてアクションキーを押します。例えば `ctrl+b` → `c` で新しいタブ。全バインドは `ctrl+b` → `?` で一覧表示できます。

この設定では、プレフィックスに加えて `ctrl+alt` の直接 chord を併設しています（プレフィックス不要）。シェルやエディタと衝突しにくい組み合わせです。

## 3. vim chord 早見表（この設定）

| 操作                      | プレフィックス             | 直接 chord                  |
| ------------------------- | -------------------------- | --------------------------- |
| ペイン移動（左/下/上/右） | `ctrl+b` → `h`/`j`/`k`/`l` | `ctrl+alt+h`/`j`/`k`/`l`    |
| 新しいタブ                | `ctrl+b` → `c`             | `ctrl+alt+c`                |
| 前/次のタブ               | `ctrl+b` → `p`/`n`         | `ctrl+alt+[` / `ctrl+alt+]` |
| 縦分割                    | `ctrl+b` → `v`             | `ctrl+alt+d`                |
| 横分割                    | `ctrl+b` → `-`             | `ctrl+alt+shift+d`          |
| ズーム                    | `ctrl+b` → `z`             | `ctrl+alt+z`                |

navigate モード（ワークスペース/ペインをキーボードで辿るモード）では素の `h`/`j`/`k`/`l` で移動します。

## 4. まず覚える5つ

| やりたいこと                   | キー                            |
| ------------------------------ | ------------------------------- |
| 新しいタブ                     | `ctrl+b` → `c`                  |
| 分割（縦/横）                  | `ctrl+b` → `v` / `ctrl+b` → `-` |
| ペイン間移動                   | `ctrl+alt+h/j/k/l`              |
| ワークスペース選択             | `ctrl+b` → `w`                  |
| detach（全部動かしたまま離脱） | `ctrl+b` → `q`                  |

detach 後は `herdr` をもう一度実行すれば再接続できます。エージェントは生きたままです。

## 5. コピーモード（vim 操作）

`ctrl+b` → `[` でコピーモードに入ります。`h/j/k/l` で移動、`w`/`b`/`e` で単語移動、`{`/`}` で段落移動、`ctrl+b`/`ctrl+f` でページ移動。`v` または Space で選択開始、`y` または Enter でコピー、`q` または Esc でコピーせず退出します。マウスのドラッグ選択でもコピーできます。

## 6. worktree とワークスペース

Git ワークスペースの行から `New worktree` で worktree チェックアウトを作れます。作成した worktree は元のワークスペースの下にグループ化された別ワークスペースとして開き、独自のタブ・ペインを持てます。チェックアウト先の削除は `Delete worktree checkout...` から明示的に行います（ブランチは消えません）。

worktree の作成先ディレクトリは config の `[worktrees] directory`（既定 `~/.herdr/worktrees`）で決まります。

## 7. エージェント連携（skill）

この dotfiles では herdr の operate skill を claude / codex に配布済みです。herdr 管理ペイン内（環境変数 `HERDR_ENV=1`）でエージェントを動かすと、エージェント自身が `herdr` CLI 経由でワークスペース作成・ペイン分割・他ペインの出力読み取り・状態変化待ちなどを行えます。`HERDR_ENV=1` が無い場合、skill は「herdr 内で動いていない」と判断して何もしません。

## 8. detach / reattach とトラブル時

- detach: `ctrl+b` → `q`。再接続は `herdr`。
- 設定を編集したら反映: `herdr server reload-config`（多くの UI 設定はペイン再起動なしで反映。起動時のみ有効な設定は再起動が必要）。
- リモート: `herdr --remote <host>` でローカル端末をリモートサーバーのクライアントにできます（画像貼り付けが維持される）。
- 既定設定の全出力: `herdr --default-config`。

## この設定をいじるには

キーバインドやテーマは `home-manager/cli/herdr/default.nix` の `settings` を編集し、`nix run .#build` で検証してから `nix run .#switch`（WSL は `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`）で反映します。config.toml は生成物なので直接編集しません。
