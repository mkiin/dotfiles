-- ========================================
-- リーダーキー設定
-- ========================================
vim.g.mapleader = " "

-- ========================================
-- エンコーディング
-- ========================================
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- ========================================
-- 表示設定
-- ========================================
vim.opt.number = true
vim.opt.title = true
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon0-blinkoff0-blinkwait0-TermCursor"

-- ========================================
-- 不可視文字
-- ========================================
vim.opt.list = true
vim.opt.listchars = {
	tab = "» ",
	trail = "·",
	nbsp = "␣",
	extends = "›",
	precedes = "‹",
}

-- ========================================
-- インデント設定
-- ========================================
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- ========================================
-- 検索設定
-- ========================================
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.inccommand = "split"
vim.opt.smartcase = true

-- ========================================
-- バックアップ・編集設定
-- ========================================
-- バックアップファイルを作成しない
vim.opt.backup = false
-- 指定パスではバックアップをスキップ（セキュリティ対策）
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
-- Backspaceキーで削除できる対象（行頭、改行、インデント）
vim.opt.backspace = { "start", "eol", "indent" }

-- ========================================
-- ウィンドウ分割設定
-- ========================================
vim.opt.splitkeep = "cursor"

-- ========================================
-- シェル・システム設定
-- ========================================
vim.opt.shell = "zsh"
vim.opt.mouse = ""

-- ========================================
-- ファイル検索設定
-- ========================================
vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })

-- ========================================
-- 装飾・見た目設定
-- ========================================
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- ========================================
-- フォーマット設定
-- ========================================
vim.opt.formatoptions:append({ "r" })

-- ========================================
-- ファイルタイプ設定
-- ========================================

-- ========================================
-- バージョン依存設定
-- ========================================
-- Neovim 0.8以降ではコマンドラインを自動非表示
if vim.fn.has("nvim-0.8") == 1 then
	vim.opt.cmdheight = 0
end

-- ========================================
-- LazyVim固有設定
-- ========================================
vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_blink_main = false
vim.g.snacks_animate = false

-- ========================================
-- 背景透過（ターミナルとの隙間を防止）
-- ========================================
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = "NONE", bg = "NONE" })
	end,
})
