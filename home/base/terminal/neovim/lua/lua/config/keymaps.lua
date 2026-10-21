vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

vim.keymap.set("n", "ss", "<cmd>split<cr>")
vim.keymap.set("n", "sv", "<cmd>vsplit<cr>")
vim.keymap.set("n", "sh", "<C-w>h")
vim.keymap.set("n", "sj", "<C-w>j")
vim.keymap.set("n", "sk", "<C-w>k")
vim.keymap.set("n", "sl", "<C-w>l")

vim.keymap.set("n", "<tab>", "<cmd>tabnext<cr>", { silent = true })
vim.keymap.set("n", "<s-tab>", "<cmd>tabprevious<cr>", { silent = true })

vim.keymap.set("t", "<C-k>", [[<C-\><C-n>]])
