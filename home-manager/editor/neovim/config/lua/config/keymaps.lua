-- ========================================
-- 共通キーマップ（VSCode + 通常Neovim）
-- ========================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 検索のハイライトのクリア
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", opts)

-- モード切り替え
map("i", "jj", "<Esc>", opts)

-- 削除操作（ヤンクしない）
map("n", "c", '"_c', opts)
map("n", "d", '"_d', opts)
map("n", "dd", '"_dd', opts)
map("n", "x", '"_d', opts)
map("n", "X", '"_D', opts)
map("x", "x", '"_x', opts)
map("o", "x", "d", opts)

-- ファンクションキーの入力を無効化
map("i", "<F14>", "<Nop>", opts)
map("i", "<F15>", "<Nop>", opts)

-- やり直し
map("n", "U", "<c-r>", { desc = "Redo" })

-- 編集操作
map("n", "Y", "y$", opts)
map({ "n", "x", "o" }, "M", "%", opts)
map("o", "i<Space>", "iW", opts)
map("x", "i<Space>", "iW", opts)

-- ビジュアルモード操作
map("x", "y", "mzy`z", opts) -- ヤンク後にカーソル位置を維持
map("x", "p", "P", opts) -- ペースト時にレジスタを上書きしない

-- t/T のデフォルト動作（f の手前版ジャンプ）を無効化
map("n", "t", "<Nop>", opts)
map("n", "T", "<Nop>", opts)

-- Split windows
map("n", "ts", "<Cmd>split<CR>", { desc = "Split horizontail" })
map("n", "tv", "<Cmd>vsplit<CR>", { desc = "Split vertical" })
map("n", "tq", "<C-w>c", { desc = "Window close" })
map("n", "tqo", "<Cmd>only<CR>", { desc = "Close Other Window" })

map("n", "<A-d>", "<Cmd>copy.<CR>", { desc = "Duplicate line below" })
map("x", "<A-d>", ":copy'><CR>gv", { desc = "Duplicate selection below" })

-- ペースト操作（インデント調整）
map("n", "p", "]p`]", opts)
map("n", "P", "]P`]", opts)
map("x", "p", "P", opts)

-- マクロ操作（qプレフィックス）
map("n", "q", function()
	return vim.fn.reg_recording() == "" and "<Plug>(q)" or "q"
end, { expr = true, remap = true })
map("n", "<Plug>(q)q", "qq", { noremap = true })
map("n", "Q", function()
	return vim.fn.reg_recording() == "" and "@q" or "q@q"
end, { expr = true, noremap = true })
map("n", "<Plug>(q)o", "<Cmd>only!<CR>", { desc = "Close other windows" })
map("n", "<Plug>(q)t", "<C-^>", { desc = "Switch to alternate buffer" })

-- 移動操作
map("n", "gf", "gF", opts) -- gf でファイルを開く時に行番号も考慮

map("n", "i", function()
	-- インサートモード開始の挙動改善（空行では cc に変換）
	if vim.bo.buftype == "terminal" then
		vim.schedule(function()
			vim.cmd("startinsert")
		end)
		return "<Ignore>"
	end
	return vim.fn.empty(vim.fn.getline(".")) == 1 and '"_cc' or "i"
end, { noremap = true, silent = true, expr = true })

map("n", "A", function()
	if vim.bo.buftype == "terminal" then
		vim.schedule(function()
			vim.cmd("startinsert!")
		end)
		return "<Ignore>"
	end
	return vim.fn.empty(vim.fn.getline(".")) == 1 and '"_cc' or "A"
end, { noremap = true, silent = true, expr = true })

map("n", "V", function()
	local count = vim.v.count
	if count > 0 then
		vim.cmd("normal! V" .. (count - 1) .. "j")
	else
		vim.cmd("normal! V")
	end
end, { noremap = true, silent = true })

-- mo: markdown viewer
require("util.mo").setup()
map("n", "<leader>mp", function()
	require("util.mo").preview()
end, { desc = "mo: preview buffer" })
map("n", "<leader>mP", function()
	require("util.mo").preview_with_group()
end, { desc = "mo: preview with group" })
map("n", "<leader>mw", function()
	require("util.mo").watch_toggle()
end, { desc = "mo: toggle watch (git repo)" })
