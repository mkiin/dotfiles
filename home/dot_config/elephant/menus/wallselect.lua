-- Elephant menu: wallselect
-- Walker 用の壁紙セレクタ。~/pictures/wallpaper/ を走査し、各ファイルを
-- サムネイル付きエントリとして返す。サムネイル描画は Walker の
-- shared_image_transformer が Icon フィールド (絶対パス) を読んで行う。
--
-- 参考実装: wiki/omarchy/default/elephant/omarchy_background_selector.lua
--   - ShellEscape / FormatName ヘルパは Omarchy からそのまま拝借
--   - Omarchy は Preview フィールドを使うが、本実装はサムネを「帯に並べる」目的で
--     Icon フィールドを使う (shared_image_transformer が絶対パス→画像ロード)

Name = "wallselect"
NamePretty = "Wallpaper Selector"
Icon = "preferences-desktop-wallpaper"
-- Cache = false 必須。true にすると elephant が GetEntries() の結果をメモリキャッシュし、
-- 新規ダウンロードした壁紙が elephant 再起動まで一覧に出ない (omarchy も false で運用)。
Cache = false
HideFromProviderlist = true
SearchName = true
Description = "pictures/wallpaper 直下の画像から壁紙を選ぶ"

local function ShellEscape(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- ファイル存在チェック (Walker の Icon パスを切り替えるのに使用)
local function FileExists(p)
	local f = io.open(p, "r")
	if f then
		f:close()
		return true
	end
	return false
end

function GetEntries()
	local entries = {}
	local home = os.getenv("HOME")
	local wallpaper_dir = home .. "/pictures/wallpaper"

	local handle = io.popen(
		"fd --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "
			.. ShellEscape(wallpaper_dir)
			.. " 2>/dev/null | sort"
	)

	-- サムネキャッシュ: wallpaper-thumb.sh が生成する 416x234 JPEG。
	-- XDG_CACHE_HOME 標準、未設定時は ~/.cache にフォールバック。
	local cache_home = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")
	local thumb_dir = cache_home .. "/wallpaper-thumbs"

	if handle then
		for path in handle:lines() do
			local filename = path:match("([^/]+)$")
			if filename then
				-- 拡張子だけ落としてファイル名をそのまま表示 (FormatName は数字接頭で不揃いになるので不採用)
				local label = filename:gsub("%.[^%.]+$", "")
				-- サムネが存在すれば軽量な方を Icon に、無ければ原画像 fallback。
				-- fallback 経路は初回実行 / cache 削除 / 生成失敗時のみ走る。
				local thumb = thumb_dir .. "/" .. label .. ".jpg"
				local icon = FileExists(thumb) and thumb or path
				table.insert(entries, {
					Text = label,
					Value = path,
					Icon = icon, -- 絶対パス → Walker が GdkTexture 化して GtkPicture に描画
					Actions = {
						activate = home .. "/.config/hypr/scripts/wallset-backend.sh " .. ShellEscape(path),
					},
				})
			end
		end
		handle:close()
	end

	return entries
end
