{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;

    keys = {
      # ペイン移動は prefix と ctrl+alt 直接 chord の二刀流（herdr 公式の prefix-free 推奨に準拠）
      focus_pane_left = [
        "prefix+h"
        "ctrl+alt+h"
      ];
      focus_pane_down = [
        "prefix+j"
        "ctrl+alt+j"
      ];
      focus_pane_up = [
        "prefix+k"
        "ctrl+alt+k"
      ];
      focus_pane_right = [
        "prefix+l"
        "ctrl+alt+l"
      ];

      # navigate モードは素の hjkl（prefix+ 不可のフィールド）
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";

      new_tab = [
        "prefix+c"
        "ctrl+alt+c"
      ];
      previous_tab = [
        "prefix+p"
        "ctrl+alt+["
      ];
      next_tab = [
        "prefix+n"
        "ctrl+alt+]"
      ];
      split_vertical = [
        "prefix+v"
        "ctrl+alt+d"
      ];
      split_horizontal = [
        "prefix+minus"
        "ctrl+alt+shift+d"
      ];
      zoom = [
        "prefix+z"
        "ctrl+alt+z"
      ];
    };
  };
in
{
  xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" settings;
}
