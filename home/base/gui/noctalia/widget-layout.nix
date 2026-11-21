{ lib, primaryOutput }:
template:
let
  mirror = primaryOutput == null;
  outputs =
    if mirror then
      [
        "eDP-1"
        "HDMI-A-1"
      ]
    else
      [ primaryOutput ];

  # An explicit output marks a widget for a secondary desktop monitor.
  ids = builtins.filter (
    id:
    let
      widget = template.widget.${id};
    in
    !(widget ? output) || (!mirror && widget.output != primaryOutput)
  ) template.widget_order;

  place =
    output: id:
    let
      widget = template.widget.${id};
      target = widget.output or output;
      name =
        if widget.type == "login_box" then
          "lockscreen-login-box@${target}"
        else if mirror then
          "${id}@${target}"
        else
          id;
      sx = 1920.0 / widget.placement_width;
      sy = 1080.0 / widget.placement_height;
    in
    lib.nameValuePair name (
      widget
      // {
        output = target;
      }
      // lib.optionalAttrs mirror {
        cx = widget.cx * sx;
        cy = widget.cy * sy;
        box_width = widget.box_width * sx;
        box_height = widget.box_height * sy;
        placement_width = 1920.0;
        placement_height = 1080.0;
      }
    );
  instances = lib.concatMap (output: map (place output) ids) outputs;
in
template
// {
  widget = builtins.listToAttrs instances;
  widget_order = map (instance: instance.name) instances;
}
