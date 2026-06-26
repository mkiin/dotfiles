{ ... }:

{
  xdg.configFile = {
    "matugen/config.toml".text = ''
      [config]
      default_mode = "dark"

      [templates.waybar]
      input_path = "~/.config/matugen/templates/waybar-colors.css"
      output_path = "~/.config/waybar/colors.css"

      [templates.wlogout]
      input_path = "~/.config/matugen/templates/wlogout-colors.css"
      output_path = "~/.config/wlogout/colors.css"

      [templates.hyprland]
      input_path = "~/.config/matugen/templates/hyprland-colors.conf"
      output_path = "~/.config/hypr/colors.conf"

      [templates.hyprland_lua]
      input_path = "~/.config/matugen/templates/hyprland-colors.lua"
      output_path = "~/.config/hypr/colors.lua"

      [templates.quickshell]
      input_path = "~/.config/matugen/templates/quickshell-colors.json"
      output_path = "~/.cache/quickshell/matugen-colors.json"
      post_hook = "for c in shell audio bluetooth; do qs -c $c ipc call theme reload 2>/dev/null; done; true"
    '';

    # ${{name}} は matugen テンプレート構文。Nix 文字列内の ${ を ''${ でエスケープ。
    "matugen/templates/hyprland-colors.conf".text = ''
      <* for name, value in colors *>
      ''${{name}} = rgb({{value.default.hex_stripped}})
      <* endfor *>

      $primary_a95            = rgba({{colors.primary.default.hex_stripped}}f2)
      $primary_fixed_a80      = rgba({{colors.primary_fixed.default.hex_stripped}}cc)
      $primary_container_a85  = rgba({{colors.primary_container.default.hex_stripped}}d9)
      $primary_container_a90  = rgba({{colors.primary_container.default.hex_stripped}}e6)
      $tertiary_a95           = rgba({{colors.tertiary.default.hex_stripped}}f2)
      $surface_a75            = rgba({{colors.surface.default.hex_stripped}}bf)
      $on_surface_a50         = rgba({{colors.on_surface.default.hex_stripped}}80)

      $state_success          = rgb(a6e3a1)
      $state_critical         = rgb(f38ba8)
      $state_success_a90      = rgba(a6e3a1e6)
      $state_critical_a90     = rgba(f38ba8e6)
    '';

    "matugen/templates/hyprland-colors.lua".text = ''
      local M = {}
      <* for name, value in colors *>
      M.{{name}} = "rgb({{value.default.hex_stripped}})"
      <* endfor *>

      M.primary_a95           = "rgba({{colors.primary.default.hex_stripped}}f2)"
      M.primary_fixed_a80     = "rgba({{colors.primary_fixed.default.hex_stripped}}cc)"
      M.primary_container_a85 = "rgba({{colors.primary_container.default.hex_stripped}}d9)"
      M.primary_container_a90 = "rgba({{colors.primary_container.default.hex_stripped}}e6)"
      M.tertiary_a95          = "rgba({{colors.tertiary.default.hex_stripped}}f2)"
      M.surface_a75           = "rgba({{colors.surface.default.hex_stripped}}bf)"
      M.on_surface_a50        = "rgba({{colors.on_surface.default.hex_stripped}}80)"

      M.state_success     = "rgb(a6e3a1)"
      M.state_critical    = "rgb(f38ba8)"
      M.state_success_a90 = "rgba(a6e3a1e6)"
      M.state_critical_a90 = "rgba(f38ba8e6)"

      return M
    '';

    "matugen/templates/waybar-colors.css".text = ''
      <* for name, value in colors *>
      @define-color {{name}} {{value.default.hex}};
      <* endfor *>

      @define-color state_success  #a6e3a1;
      @define-color state_warning  #f9e2af;
      @define-color state_critical #f38ba8;
    '';

    "matugen/templates/wlogout-colors.css".text = ''
      <* for name, value in colors *>
      @define-color {{name}} {{value.default.hex}};
      <* endfor *>
    '';

    "matugen/templates/quickshell-colors.json".text = ''
      {
        "background": "{{colors.background.default.hex}}",
        "foreground": "{{colors.on_surface.default.hex}}",
        "cursor":     "{{colors.primary.default.hex}}",

        "primary":            "{{colors.primary.default.hex}}",
        "onPrimary":          "{{colors.on_primary.default.hex}}",
        "primaryContainer":   "{{colors.primary_container.default.hex}}",
        "onPrimaryContainer": "{{colors.on_primary_container.default.hex}}",

        "secondary":          "{{colors.secondary.default.hex}}",
        "onSecondary":        "{{colors.on_secondary.default.hex}}",
        "secondaryContainer": "{{colors.secondary_container.default.hex}}",

        "tertiary":           "{{colors.tertiary.default.hex}}",
        "onTertiary":         "{{colors.on_tertiary.default.hex}}",
        "tertiaryContainer":  "{{colors.tertiary_container.default.hex}}",

        "surface":                   "{{colors.surface.default.hex}}",
        "surfaceDim":                "{{colors.surface_dim.default.hex}}",
        "surfaceBright":             "{{colors.surface_bright.default.hex}}",
        "surfaceContainerLowest":    "{{colors.surface_container_lowest.default.hex}}",
        "surfaceContainerLow":       "{{colors.surface_container_low.default.hex}}",
        "surfaceContainer":          "{{colors.surface_container.default.hex}}",
        "surfaceContainerHigh":      "{{colors.surface_container_high.default.hex}}",
        "surfaceContainerHighest":   "{{colors.surface_container_highest.default.hex}}",
        "surfaceVariant":            "{{colors.surface_variant.default.hex}}",

        "onSurface":        "{{colors.on_surface.default.hex}}",
        "onSurfaceVariant": "{{colors.on_surface_variant.default.hex}}",

        "outline":        "{{colors.outline.default.hex}}",
        "outlineVariant": "{{colors.outline_variant.default.hex}}",

        "error":          "{{colors.error.default.hex}}",
        "onError":        "{{colors.on_error.default.hex}}",
        "errorContainer": "{{colors.error_container.default.hex}}",

        "inverseSurface":   "{{colors.inverse_surface.default.hex}}",
        "inverseOnSurface": "{{colors.inverse_on_surface.default.hex}}",
        "inversePrimary":   "{{colors.inverse_primary.default.hex}}",

        "scrim":  "{{colors.scrim.default.hex}}",
        "shadow": "{{colors.shadow.default.hex}}",

        "success":   "#a6e3a1",
        "onSuccess": "{{colors.background.default.hex}}",
        "warning":   "#f9e2af",
        "onWarning": "{{colors.background.default.hex}}",
        "info":      "{{colors.primary.default.hex}}",

        "colors": {
          "color0":  "{{colors.surface.default.hex}}",
          "color1":  "{{colors.error.default.hex}}",
          "color2":  "{{colors.tertiary.default.hex}}",
          "color3":  "{{colors.secondary.default.hex}}",
          "color4":  "{{colors.primary.default.hex}}",
          "color5":  "{{colors.secondary.default.hex}}",
          "color6":  "{{colors.tertiary.default.hex}}",
          "color7":  "{{colors.on_surface.default.hex}}",
          "color8":  "{{colors.on_surface_variant.default.hex}}",
          "color9":  "{{colors.error.default.hex}}",
          "color10": "{{colors.tertiary.default.hex}}",
          "color11": "{{colors.secondary.default.hex}}",
          "color12": "{{colors.primary.default.hex}}",
          "color13": "{{colors.secondary.default.hex}}",
          "color14": "{{colors.tertiary.default.hex}}",
          "color15": "{{colors.on_surface.default.hex}}"
        }
      }
    '';
  };
}
