{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    profiles.default = {
      settings = {
        "browser.tabs.warnOnClose" = false;

        # 定番UX
        "zen.welcome-screen.seen" = true;
        "browser.aboutConfig.showWarning" = false;
        "zen.workspaces.continue-where-left-off" = true;

        # コンパクトモード + フロートURLバー
        "zen.view.compact.hide-tabbar" = true;
        "zen.urlbar.behavior" = "float";

        # プライバシー / テレメトリ off
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;

        # タブ運用
        "zen.tabs.dim-pending" = true;
        "zen.ctrlTab.show-pending-tabs" = true;

        # 言語（Accept-Language ヘッダのみ）
        "intl.accept_languages" = "ja,en-US,en";

        # フォント（ja = 日本語 / x-western = 欧文）
        "font.name.serif.ja" = "Noto Serif CJK JP";
        "font.name.sans-serif.ja" = "Noto Sans CJK JP";
        "font.name.monospace.ja" = "UDEV Gothic";
        "font.default.ja" = "sans-serif";
        "font.name.serif.x-western" = "Noto Serif";
        "font.name.sans-serif.x-western" = "Inter";
        "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
      };

      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "5d4c9e3d-e72a-4bd3-9c28-a0890768ded1";
          position = 1000;
          icon = "🏠";
        };
        "Dev" = {
          id = "e3e428d8-c7e8-4d3b-9e29-d10aa3f80cae";
          position = 2000;
          icon = "💻";
        };
      };

      mods = [
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
      ];

      bookmarks = import ./bookmarks.nix;
    };
  };
}
