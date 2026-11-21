{ lib, ... }:
let
  desktop =
    (import ../../base/gui/noctalia/desktop.nix { }).programs.noctalia.settings.desktop_widgets;
  lockscreen =
    (import ../../base/gui/noctalia/lockscreen.nix { }).programs.noctalia.settings.lockscreen_widgets;
  outputs = [
    "eDP-1"
    "HDMI-A-1"
  ];
  onBothScreens =
    template: sourceOutput:
    let
      ids = builtins.filter (id: template.widget.${id}.output == sourceOutput) template.widget_order;
      instances = lib.concatMap (
        output:
        map (
          id:
          let
            widget = template.widget.${id};
            sx = 1920.0 / widget.placement_width;
            sy = 1080.0 / widget.placement_height;
          in
          lib.nameValuePair
            (if widget.type == "login_box" then "lockscreen-login-box@${output}" else "${id}@${output}")
            (
              widget
              // {
                inherit output;
                cx = widget.cx * sx;
                cy = widget.cy * sy;
                box_width = widget.box_width * sx;
                box_height = widget.box_height * sy;
                placement_width = 1920.0;
                placement_height = 1080.0;
              }
            )
        ) ids
      ) outputs;
    in
    template
    // {
      widget = builtins.listToAttrs instances;
      widget_order = map (instance: instance.name) instances;
    };
in
{
  programs.noctalia.settings = {
    desktop_widgets = lib.mkForce (onBothScreens desktop "DP-1");
    lockscreen_widgets = lib.mkForce (onBothScreens lockscreen "DP-2");
  };
}
