{ ... }:
{
  programs.noctalia.settings = {
    lockscreen = {
      enabled = true;
      lock_before_suspend = true;
      blur_intensity = 0.0;
      allow_empty_password = true;
    };

    # Widget layouts are intentionally owned by Noctalia's interactive editors.
    # Do not declare widget_order/widget here, or GUI layout changes will be overridden.
    desktop_widgets.enabled = true;
    lockscreen_widgets.enabled = true;
  };
}
