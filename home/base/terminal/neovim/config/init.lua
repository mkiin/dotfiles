-- ========================================
-- Neovim 設定エントリーポイント
-- ========================================

-- コア設定の読み込み
if vim.loader then
	vim.loader.enable()
end

require("config.lazy")
require("config.clipboard")
