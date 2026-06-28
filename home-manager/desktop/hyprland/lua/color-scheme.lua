local ok, colors = pcall(require, "colors")
if not ok then return end

hl.config({
  general = {
    ["col.active_border"]   = { colors = { colors.primary, colors.tertiary }, angle = 45 },
    ["col.inactive_border"] = colors.outline_variant,
  },
  group = {
    ["col.border_active"]          = { colors = { colors.primary, colors.tertiary }, angle = 45 },
    ["col.border_inactive"]        = colors.outline_variant,
    ["col.border_locked_active"]   = { colors = { colors.primary, colors.tertiary }, angle = 45 },
    ["col.border_locked_inactive"] = colors.outline_variant,
  },
})
