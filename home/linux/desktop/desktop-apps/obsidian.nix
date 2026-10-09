{ pkgs, myvars, ... }:
let
  obsidianGit = pkgs.fetchzip {
    name = "obsidian-git-2.41.1";
    url = "https://github.com/Vinzent03/obsidian-git/releases/download/2.41.1/obsidian-git-2.41.1.zip";
    hash = "sha256-HmaLo9x4sl2axmfsUKvD0J5QzjYtL7iiiVcMMnQ+q1g=";
    passthru.manifestId = "obsidian-git";
  };
in
{
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
          "canvas"
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
          {
            pkg = obsidianGit;

            settings = {
              # 編集が止まってから5分後に自動 commit → pull → push
              autoSaveInterval = 5;
              autoBackupAfterFileChange = true;
              differentIntervalCommitAndPush = false;

              # 起動時に pull。独立した定期 pull / push は無効
              autoPullOnBoot = true;
              autoPullInterval = 0;
              autoPushInterval = 0;

              # 自動・手動 sync 時は pull → push
              pullBeforePush = true;
              disablePush = false;

              autoCommitMessage = "vault backup: {{date}}";
              commitDateFormat = "YYYY-MM-DD HH:mm:ss";

              syncMethod = "merge";
              mergeStrategy = "none";

              showStatusBar = true;
              showBranchStatusBar = true;
              changedFilesInStatusBar = true;
              updateSubmodules = false;
            };
          }

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
