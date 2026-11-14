---@type snacks.dashboard.Config
return {
  enabled = true,
  formats = {},
  sections = {
    { section = "header" },
    { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
    { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
    { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
    { section = "startup" },
  },
  autokeys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
  preset = {
    keys = {
      { icon = "", desc = "New file", key = "e", action = ":enew | startinsert" },
      { icon = "󰈙", desc = "Files", key = "f", action = ":lua Snacks.picker.smart()" },
      { icon = "", desc = "Grep", key = "g", action = ":lua Snacks.picker.grep()" },
      { icon = "", desc = "Recent files", key = "r", action = ":lua Snacks.picker.recent()" },
      { icon = "", desc = "Dotfiles", key = "d", action = ":ConfigFiles" },
      { icon = "", desc = "Restore session", key = "s", section = "session" },
      { icon = "󰒲", desc = "Lazy", key = "z", action = ":Lazy" },
      { icon = "󰅚", desc = "Quit", key = "q", action = ":qa" },
    },
  },
}
