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
Cache = true
HideFromProviderlist = true
SearchName = true
Description = "pictures/wallpaper 直下の画像から壁紙を選ぶ"

local function ShellEscape(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function FormatName(filename)
    local name = filename:gsub("^%d+", ""):gsub("^%-", "")
    name = name:gsub("%.[^%.]+$", "")
    name = name:gsub("-", " ")
    name = name:gsub("%S+", function(word)
        return word:sub(1, 1):upper() .. word:sub(2):lower()
    end)
    return name
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

    if handle then
        for path in handle:lines() do
            local filename = path:match("([^/]+)$")
            if filename then
                -- 拡張子だけ落としてファイル名をそのまま表示 (FormatName は数字接頭で不揃いになるので不採用)
                local label = filename:gsub("%.[^%.]+$", "")
                table.insert(entries, {
                    Text = label,
                    Value = path,
                    Icon = path, -- 絶対パス → Walker が GdkTexture 化して GtkPicture に描画
                    Actions = {
                        activate = home .. "/.config/hypr/scripts/wallpaper.sh " .. ShellEscape(path),
                    },
                })
            end
        end
        handle:close()
    end

    return entries
end
