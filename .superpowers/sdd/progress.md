# SDD progress: nixos-flake-restructure
Task 0: complete (commits f26de11..0570b03, review clean, mkStable hoisted; minor mkForce/groups deferred to Phase 2 users.nix)
Task 1: complete (commits 8a15b85..0c27ad8, review clean after neovim→lnk fix; minor {...}→_ deferred)
Task 2 (system layer): files done, dry-build evaluates OK (commit 3faed55). Switch deferred until Phase 3 desktop config ready. mise nix-ld libs deferred per user.
Task 3 (home desktop): complete (..236f7d5), dry-build OK, session binaries present, hardcoded paths fixed, hyprland cachix added. Switch-ready.
Phase2 fix: blacklist amdgpu (hybrid wrong-GPU root cause; weston/hyprland grabbed iGPU w/ no monitor). committed 6b4f704
Phase desktop polish: fonts→system, zen declarative(beta)+bookmarks, bt-agent→system, monitor/browser/waybar fixed. nixos uses <name>/default.nix.
Task zen-1: complete (commit 5632763, review clean; Noto Serif欧文は noto-fonts 実在フォントで設計通り)
Task zen-2: complete (commit e351e6e, review clean; spaces+mods追加、settings無改変確認)
Zen feature: final whole-branch review clean (4c05a4b..e351e6e, マージ可・指摘なし). Task3(apply+GUI検証)は人手(sudo nixos-rebuild switch + Zen目視)で未実施。
Zen feature: settings全カテゴリ拡張完了 (commit ac075c7, review clean: spec準拠/決定事項準拠/品質Approved). spaces/mods/bookmarks維持確認済み。Task3(sudo switch+GUI検証)は人手で未実施。

## auto-fmt-hook feature
Task 1: complete (commits 7a49e1f..6e104fc, review clean). treefmt定義 lib/treefmt/default.nix。レビューでmatugenテンプレ(stylua/prettierハードフェイル)・lazy-lock churn・shfmt zshスキップ・prettier対象過大をincludes/excludesで修正。M1(statix/nixfmt priority冪等性)はTask2統合後に実測判断へ保留。
