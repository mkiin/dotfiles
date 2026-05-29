local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux
local act = wezterm.action

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- WSL2 Ubuntu をデフォルト (Windows 版 wezterm のみ)
if is_windows then
	config.default_domain = "WSL:Ubuntu-24.04"
end
config.automatically_reload_config = true
config.front_end = "OpenGL"

-- 起動時に最大化
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- ビープ音を無効化
config.audible_bell = "Disabled"

-- フォント
config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"BIZ UDGothic",
})
config.font_size = 14.0

-- カラー
config.color_scheme = "Snazzy (base16)"

-- IME
config.use_ime = true

-- ウィンドウの見た目
config.window_background_opacity = 0.7
config.window_decorations = "RESIZE | TITLE"
if is_windows then
	config.win32_system_backdrop = "Acrylic"
end

-- タブバーの設定
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false

-- リーダーキー
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }

-- キーバインド
config.keys = {
	-- ========================================
	-- タブ操作
	-- ========================================
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) }, -- 前のタブ
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) }, -- 次のタブ

	-- ========================================
	-- ペイン操作
	-- ========================================
	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "m", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState }, -- ペインズーム

	-- ========================================
	-- ペイン操作セクションキー
	-- ========================================
	{ key = "e", mods = "LEADER", action = act.PaneSelect },

	-- ペイン間移動
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	-- ペインサイズ調整モード
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- ========================================
	-- コピーモード・コマンドパレット
	-- ========================================
	{ key = "c", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },

	-- ========================================
	-- 番号でタブ移動
	-- ========================================
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },

	-- ========================================
	-- 新しいウィンドウを生成
	-- ========================================
	{ key = "w", mods = "LEADER", action = act.SpawnWindow },

	-- ========================================
	-- F14・F15キーを無効化
	-- ========================================
	{ key = "F14", mods = "NONE", action = act.Nop },
	{ key = "F15", mods = "NONE", action = act.Nop },
}

-- ========================================
-- 右クリックでペースト動作
-- ========================================
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
}

-- ========================================
-- キーテーブル（モード）
-- ========================================
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
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
-- 無い時 (初回 / Windows) は上の color_scheme にフォールバック。
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
