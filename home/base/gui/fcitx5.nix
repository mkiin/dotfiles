{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  layout = osConfig.services.xserver.xkb.layout;
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        qt6Packages.fcitx5-configtool
        fcitx5-gtk
        fcitx5-mozc-ut
      ];

      settings = {
        globalOptions = {
          "Hotkey/TriggerKeys" = lib.mkIf (layout == "jp") {
            "0" = "Zenkaku_Hankaku";
          };

          "Hotkey/ActivateKeys" = {
            "0" = "Alt+Alt_R";
            "1" = lib.mkIf (layout == "jp") "Henkan";
          };

          "Hotkey/DeactivateKeys" = {
            "0" = "Alt+Alt_L";
            "1" = lib.mkIf (layout == "jp") "Muhenkan";
          };

          "Hotkey/PrevCandidate" = {
            "0" = "Shift+Tab";
          };

          "Hotkey/NextCandidate" = {
            "0" = "Tab";
          };

          Behavior = {
            ActiveByDefault = false;
            ShareInputState = "No";
            PreeditEnabledByDefault = true;
            DefaultPageSize = 5;
            AllowInputMethodForPassword = false;
            ShowPreeditForPassword = false;
          };

          "Behavior/DisabledAddons" = {
            "0" = "fcitx4frontend";
            "1" = "ibusfrontend";
            "2" = "kimpanel";
            "3" = "virtualkeyboard";
          };
        };

        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = layout;
            DefaultIM = "mozc";
          };

          "Groups/0/Items/0" = {
            Name = "keyboard-${layout}";
          };

          "Groups/0/Items/1" = {
            Name = "mozc";
          };

          GroupOrder = {
            "0" = "Default";
          };
        };

        addons = {
          classicui = {
            globalSection = {
              Theme = "noctalia";
              DarkTheme = "noctalia";
              VerticalCandidateList = false;
              WheelForPaging = true;
              PerScreenDPI = false;
            };
          };

          keyboard = {
            sections = {
              "Hint Trigger" = {
                "0" = "Control+Alt+Insert";
              };

              "One Time Hint Trigger" = {
                "0" = "Control+Alt+End";
              };
            };
          };
        };
      };
    };
  };
}
