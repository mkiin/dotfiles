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
      bookmarks = import ./bookmarks.nix;
    };
  };
}
