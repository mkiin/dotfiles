local M = {}

M.terminal = os.getenv("TERMINAL") or "ghostty"
M.fileManager = os.getenv("FILE_MANAGER") or "wezterm start -- yazi"
M.browser = os.getenv("BROWSER") or "zen-beta"
M.mainMod = "SUPER"

return M
