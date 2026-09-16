{
  vars,
  ...
}:

{
  programs.obsidian = {
    enable = true;

    vaults.main = {
      target = "ghq/github.com/${vars.username}/obsidian-store";

      settings = {
        # ~/.obsidian/app.json 相当
        app = {
          # Vim key bindings
          vimMode = true;
          # Editor
          showLineNumber = true;
          # 1行を狭く制限しない
          readableLineLength = false;
        };

        # ~/.obsidian/appearance.json 相当
        appearance = {
          # UI / editor font size
          baseFontSize = 16;
          interfaceFontFamily = "Noto Sans";
          textFontFamily = "Noto Sans";
          monospaceFontFamily = "JetBrainsMono Nerd Font";
        };

        # Obsidian 標準プラグイン
        corePlugins = [
          # Navigation
          "file-explorer"
          "global-search"
          "switcher"
          "command-palette"

          # Links
          "backlink"
          "outgoing-link"
          "page-preview"

          # Metadata / structure
          "properties"
          "outline"
          "tag-pane"

          # Notes
          "daily-notes"
          "templates"
          "bookmarks"

          # Utility
          "word-count"
          "file-recovery"

          # --- Optional ---

          # Visualize note relationships
          # "graph"

          # Free-form visual workspace
          # "canvas"

          # Multiple workspace layouts
          # "workspaces"

          # Generate unique timestamp-based notes
          # "zk-prefixer"

          # Random note
          # "random-note"

          # Markdown slides
          # "slides"

          # Audio recording
          # "audio-recorder"

          # Slash command menu
          # "slash-command"

          # Merge / extract note contents
          # "note-composer"

          # Import Markdown from external formats
          # "markdown-importer"

          # Obsidian Bases
          # "bases"

          # Web viewer
          # "webviewer"

          # Obsidian Publish
          # "publish"

          # Obsidian Sync
          # "sync"
        ];

        # Community plugins
        #
        # Home Manager が plugin 本体と.obsidian/plugins/<plugin>/data.json を管理する。
        communityPlugins = [
          # Obsidian Git
          #
          # {
          #   pkg = pkgs.obsidianPlugins.obsidian-git;
          #
          #   settings = {
          #     # 自動 commit
          #     autoSaveInterval = 5;
          #     autoBackupAfterFileChange = true;
          #
          #     # 起動時に pull
          #     autoPullOnBoot = true;
          #
          #     # 定期 pull / push は最初は無効
          #     autoPullInterval = 0;
          #     autoPushInterval = 0;
          #
          #     # sync 時は pull → push
          #     pullBeforePush = true;
          #     disablePush = false;
          #
          #     # commit message
          #     autoCommitMessage = "vault backup: {{date}}";
          #     commitDateFormat = "YYYY-MM-DD HH:mm:ss";
          #
          #     # merge
          #     syncMethod = "merge";
          #     mergeStrategy = "none";
          #
          #     # UI
          #     showStatusBar = true;
          #     showBranchStatusBar = true;
          #     changedFilesInStatusBar = true;
          #
          #     updateSubmodules = false;
          #   };
          # }

          # ほかの community plugin も同じ形式
          #
          # {
          #   pkg = pkgs.obsidianPlugins.<plugin-name>;
          #   settings = {
          #     ...
          #   };
          # }
        ];

        # Hotkeys
        #
        # command ID ごとに設定できる。
        hotkeys = {
          # 例:
          #
          # "app:go-back" = [
          #   {
          #     modifiers = [ "Mod" ];
          #     key = "ArrowLeft";
          #   }
          # ];
          #
          # "app:go-forward" = [
          #   {
          #     modifiers = [ "Mod" ];
          #     key = "ArrowRight";
          #   }
          # ];
        };

        # Themes
        themes = [
          # nixpkgs に収録されている theme を使う場合
          #
          # pkgs.obsidianThemes.<theme-name>
        ];

        # CSS snippets
        cssSnippets = [
          # 例:
          #
          # {
          #   name = "custom";
          #   source = ./custom.css;
          # }
        ];

        # Vault 直下に追加したいファイル
        extraFiles = {
          # 例:
          #
          # ".gitignore".text = ''
          #   .trash/
          # '';
        };
      };
    };
  };
}
