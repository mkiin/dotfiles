{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout     = "us";
      kb_options    = "caps:none";
      repeat_rate   = 40;
      repeat_delay  = 250;
      follow_mouse  = 1;
      accel_profile = "flat";
      sensitivity   = 1.0;
      scroll_factor = 2;
      touchpad = {
        natural_scroll = false;
      };
    };

    gesture = "3, horizontal, workspace";

    cursor = {
      no_warps             = false;
      sync_gsettings_theme = false;
      enable_hyprcursor    = true;
    };

    env = [
      "XCURSOR_THEME,phinger-cursors-light"
      "HYPRCURSOR_THEME,phinger-cursors-light"
      "XCURSOR_SIZE,40"
      "HYPRCURSOR_SIZE,40"
      "XMODIFIERS,@im=fcitx"
      "GTK_IM_MODULE,fcitx"
      "QT_IM_MODULE,fcitx"
      "QT_QPA_PLATFORMTHEME,gtk3"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "LIBVA_DRIVER_NAME,nvidia"
      "NVD_BACKEND,direct"
      "ELECTRON_OZONE_PLATFORM_HINT,auto"
    ];
  };
}
