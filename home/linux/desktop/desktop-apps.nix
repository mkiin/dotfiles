{ myvars, ... }:
{
  programs.vesktop = {
    enable = true;

    settings = {
      tray = true;
      minimizeToTray = true;
      hardwareAcceleration = true;
      arRPC = true;
    };
  };

  programs.obsidian = {
    enable = true;

    vaults.main = {
      target = "ghq/github.com/${myvars.username}/obsidian-store";

      settings = {
        # ~/.obsidian/app.json 相当
        app = {
          vimMode = true;
          showLineNumber = true;
          readableLineLength = false;
        };

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

          # "graph"
          # "canvas"
          # "workspaces"
          # "zk-prefixer"
          # "random-note"
          # "slides"
          # "audio-recorder"
          # "slash-command"
          # "note-composer"
          # "markdown-importer"
          # "bases"
          # "webviewer"
          # "publish"
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

        hotkeys = { };

        themes = [
          # pkgs.obsidianThemes.<theme-name>
        ];

        # CSS snippets
        cssSnippets = [ ];

        extraFiles = { };
      };
    };
  };
}
