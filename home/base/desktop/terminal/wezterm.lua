local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux
local act = wezterm.action

config.automatically_reload_config = true
config.enable_tab_bar = false
config.use_ime = true
config.front_end = "OpenGL"
config.font_size = 14.0
config.color_scheme = "Snazzy (base16)"
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.window_background_opacity = 0.9
config.window_decorations = "RESIZE | TITLE"

-- 起動時に最大化
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"UDEV Gothic",
	"DejaVu Sans Mono",
})

-- このリストは既定値を上書きするため、シェル類を再掲した上で yazi を追加
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"sh",
	"zsh",
	"fish",
	"tmux",
	"nu",
	"cmd.exe",
	"pwsh.exe",
	"powershell.exe",
	"yazi",
}

config.leader = { key = "VoidSymbol", mods = "", timeout_milliseconds = 1000 }

config.keys = {
	-- 移動ペイン
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- 移動タブ
	{ key = "H", mods = "LEADER|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "LEADER", action = act.ActivateLastTab },

	-- 移動スクロール
	{ key = "J", mods = "LEADER|SHIFT", action = act.ScrollByPage(1) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.ScrollByPage(-1) },
	{ key = "g", mods = "LEADER", action = act.ScrollToTop },
	{ key = "G", mods = "LEADER|SHIFT", action = act.ScrollToBottom },

	-- 移動プロンプト
	{ key = ",", mods = "LEADER", action = act.ScrollToPrompt(-1) },
	{ key = ".", mods = "LEADER", action = act.ScrollToPrompt(1) },

	-- 移動リサイズモード
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- 分割
	{ key = "s", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- 左右
	{ key = "v", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- 上下

	-- ペイン操作
	{ key = "m", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "e", mods = "LEADER", action = act.PaneSelect },

	-- タブ操作
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },

	-- コピーモード / その他
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "w", mods = "LEADER", action = act.SpawnWindow },
	{ key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },

	-- 既定の Shift+PageUp/Down スクロールを無効化
	{ key = "PageUp", mods = "SHIFT", action = act.DisableDefaultAssignment },
	{ key = "PageDown", mods = "SHIFT", action = act.DisableDefaultAssignment },

	-- 既定の Ctrl+f / Ctrl+Shift+f (Search = 検索モード起動) を無効化
	{ key = "f", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "f", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
	{ key = "F", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
}

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "Enter", action = "PopKeyTable" },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

config.colors = {
	tab_bar = {
		background = "none",
	},
}

-- wallust 連動パレット。壁紙変更で再生成され watch list 経由で自動リロード。
-- 無い時は上の color_scheme にフォールバック。
local wallust_scheme = wezterm.config_dir .. "/colors/wallust.toml"
local wf = io.open(wallust_scheme, "r")
if wf then
	wf:close()
	local ok, palette = pcall(wezterm.color.load_scheme, wallust_scheme)
	if ok and palette then
		palette.tab_bar = config.colors.tab_bar
		config.colors = palette
		wezterm.add_to_config_reload_watch_list(wallust_scheme)
	end
end

return config
