{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      {
        name           = "suppress-maximize-events";
        "match:class"  = ".*";
        suppress_event = "maximize";
      }
      {
        name               = "fix-xwayland-drags";
        "match:class"      = "^$";
        "match:title"      = "^$";
        "match:xwayland"   = true;
        "match:float"      = true;
        "match:fullscreen" = false;
        "match:pin"        = false;
        no_focus           = true;
      }
      {
        name          = "move-hyprland-run";
        "match:class" = "hyprland-run";
        move          = "20 monitor_h-120";
        float         = true;
      }
      {
        name          = "float-guvcview";
        "match:class" = "^guvcview$";
        float         = true;
      }
      {
        name          = "float-pwvucontrol";
        "match:class" = "^com\\.saivert\\.pwvucontrol$";
        float         = true;
        size          = "700 800";
        center        = 1;
      }
      {
        # Wine の explorer.exe /desktop が NIKKE セッション中に常に上層に出てくるのを抑制
        name             = "hide-wine-explorer-desktop";
        "match:class"    = "^steam_proton$";
        "match:title"    = "^$";
        "match:xwayland" = true;
        workspace        = "special silent";
        no_focus         = true;
      }
    ];

    layerrule = [
      "blur on, match:namespace logout_dialog"
      "dim_around on, match:namespace logout_dialog"
    ];
  };
}
