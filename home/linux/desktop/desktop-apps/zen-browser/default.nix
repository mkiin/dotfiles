{
  inputs,
  pkgs,
  ...
}:

let
  missav-keep-playing = import ./extensions/missav-keep-playing/xpi.nix {
    inherit pkgs;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  xdg.dataFile."icons/hicolor/scalable/apps/zen-beta.svg".source =
    "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/zen-browser.svg";

  programs.zen-browser = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };

    profiles.default = {
      extensions.packages = [
        missav-keep-playing
      ];

      settings = {
        # Browser behavior
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.ctrlTab.sortByRecentlyUsed" = true;

        "browser.startup.page" = 3;

        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.aboutConfig.showWarning" = false;
        "findbar.highlightAll" = true;

        # Zen
        "zen.workspaces.continue-where-left-off" = true;
        "zen.urlbar.behavior" = "float";

        # Unsigned custom extension
        "xpinstall.signatures.required" = false;

        # Privacy
        "privacy.globalprivacycontrol.enabled" = true;
        "dom.security.https_only_mode" = true;

        # URL bar
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

        # Notifications
        "permissions.default.desktop-notification" = 2;
        "dom.push.enabled" = false;

        # Downloads: ask every time
        "browser.download.useDownloadDir" = false;

        # UI
        "widget.gtk.overlay-scrollbars.enabled" = false;

        # Locale
        "intl.accept_languages" = "ja,en-US,en";

        # Default / fallback fonts
        "font.name.serif.ja" = "Noto Serif CJK JP";
        "font.name.sans-serif.ja" = "Noto Sans CJK JP";
        "font.name.monospace.ja" = "UDEV Gothic";
        "font.default.ja" = "sans-serif";

        "font.name.serif.x-western" = "Noto Serif";
        "font.name.sans-serif.x-western" = "Inter";
        "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
      };

      spaces = {
        Personal = {
          id = "5d4c9e3d-e72a-4bd3-9c28-a0890768ded1";
          position = 1000;
          icon = "🏠";
        };

        Dev = {
          id = "e3e428d8-c7e8-4d3b-9e29-d10aa3f80cae";
          position = 2000;
          icon = "💻";
        };
      };

      mods = [
        # URL bar の Top Sites を非表示
        "e122b5d9-d385-4bf8-9971-e137809097d0"
      ];

      settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };
  };
}
