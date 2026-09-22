{ pkgs, ... }:
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
          "Hotkey/ActivateKeys" = {
            "0" = "Alt+Alt_R";
          };

          "Hotkey/DeactivateKeys" = {
            "0" = "Alt+Alt_L";
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
            "Default Layout" = "us";
            DefaultIM = "mozc";
          };

          "Groups/0/Items/0" = {
            Name = "keyboard-us";
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
