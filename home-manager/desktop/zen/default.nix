{ inputs, pkgs, ... }:
let
  firefox-addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    profiles.default = {
      extensions.packages = with firefox-addons; [
        ublock-origin
      ];

      settings = {
        "browser.tabs.warnOnClose" = false;

        # Look and Feel / Appearance
        "zen.welcome-screen.seen" = true;
        "zen.watermark.enabled" = false;
        "zen.view.compact.hide-tabbar" = true;
        "zen.urlbar.behavior" = "float";
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.aboutConfig.showWarning" = false;

        # Tab Management / Tabs and Browsing
        "zen.workspaces.continue-where-left-off" = true;
        "browser.startup.page" = 3;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "zen.tabs.dim-pending" = true;
        "zen.ctrlTab.show-pending-tabs" = true;
        "extensions.pocket.enabled" = false;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

        # Privacy and Security
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "dom.security.https_only_mode" = true;
        "network.cookie.cookieBehavior" = 5;
        "network.trr.mode" = 2;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;

        # Permissions and Data（通知のみブロック / 自動再生は音声のみ）
        "permissions.default.desktop-notification" = 2;
        "dom.push.enabled" = false;
        "media.autoplay.default" = 1;

        # Downloads
        "browser.download.useDownloadDir" = true;
        "browser.download.folderList" = 2;
        "browser.download.dir" = "/home/mkiin/Downloads";

        # Accessibility
        "widget.gtk.overlay-scrollbars.enabled" = false;
        "findbar.highlightAll" = true;

        # Languages（Accept-Language ヘッダのみ）
        "intl.accept_languages" = "ja,en-US,en";

        # Fonts（ja = 日本語 / x-western = 欧文）
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
