{ ... }:

{
  wayland.windowManager.hyprland = {
    settings = {
      gesture = {
        fingers   = 3;
        direction = "horizontal";
        action    = "workspace";
      };

      env = [
        { _args = ["XCURSOR_THEME"               "phinger-cursors-light"]; }
        { _args = ["HYPRCURSOR_THEME"             "phinger-cursors-light"]; }
        { _args = ["XCURSOR_SIZE"                 "40"]; }
        { _args = ["HYPRCURSOR_SIZE"              "40"]; }
        { _args = ["XMODIFIERS"                   "@im=fcitx"]; }
        { _args = ["GTK_IM_MODULE"                "fcitx"]; }
        { _args = ["QT_IM_MODULE"                 "fcitx"]; }
        { _args = ["QT_QPA_PLATFORMTHEME"         "gtk3"]; }
        { _args = ["GBM_BACKEND"                  "nvidia-drm"]; }
        { _args = ["__GLX_VENDOR_LIBRARY_NAME"    "nvidia"]; }
        { _args = ["LIBVA_DRIVER_NAME"            "nvidia"]; }
        { _args = ["NVD_BACKEND"                  "direct"]; }
        { _args = ["ELECTRON_OZONE_PLATFORM_HINT" "auto"]; }
      ];
    };

    extraConfig = ''
      hl.config({
        input = {
          kb_layout     = "us",
          kb_options    = "caps:none",
          repeat_rate   = 40,
          repeat_delay  = 250,
          follow_mouse  = 1,
          accel_profile = "flat",
          sensitivity   = 1.0,
          scroll_factor = 2,
          touchpad = { natural_scroll = false },
        },
        cursor = {
          no_warps             = false,
          sync_gsettings_theme = false,
          enable_hyprcursor    = true,
        },
      })
    '';
  };
}
