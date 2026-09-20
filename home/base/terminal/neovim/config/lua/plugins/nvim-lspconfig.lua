return {
	"neovim/nvim-lspconfig",
	opts = {
		inlay_hints = {
			enabled = false,
		},
		servers = {
			["*"] = {
				keys = {
					{
						"gD",
						"<cmd>FzfLua lsp_declarations jump1=true ignore_current_line=true<cr>",
						desc = "Goto Declaration",
						has = "declaration",
					},
				},
			},
			tsgo = {
				server_capabilities = {
					documentFormattingProvider = false,
					documentRangeFormattingProvider = false,
					documentOnTypeFormattingProvider = false,
				},
			},
			lua_ls = {
				-- .git を root マーカーにすると dotfiles 等の非 Lua リポジトリ全体を走査し、
				-- result/.direnv 経由で /nix/store まで辿って応答が返らなくなる
				root_markers = {
					{ ".emmyrc.json", ".luarc.json", ".luarc.jsonc" },
					{ ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
				},
			},
			nixd = {},
			bashls = {},
			clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=never",
					"--query-driver=**/bin/xtensa-*-elf-*,**/bin/riscv32-*-elf-*",
				},
				capabilities = {
					offsetEncoding = { "utf-16" },
				},
			},
		},
	},
}
