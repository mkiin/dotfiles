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
