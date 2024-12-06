return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"williamboman/mason-lspconfig.nvim",
				config = function()
					require("mason-lspconfig").setup({
						ensure_installed = {
							"bashls",
							"clangd",
							"cssls",
							"emmet_ls",
							"gopls",
							"html",
							"jdtls",
							"jsonls",
							"lua_ls",
							"pyright",
							"rust_analyzer",
						},
					})
				end,
			},
		},
		config = function()
			local lspconfig = require("lspconfig")
			lspconfig.bashls.setup({})
			lspconfig.clangd.setup({})
			lspconfig.cssls.setup({})
			lspconfig.emmet_ls.setup({})
			lspconfig.gopls.setup({})
			lspconfig.html.setup({})
			lspconfig.jdtls.setup({})
			lspconfig.jsonls.setup({})
			lspconfig.lua_ls.setup({})
			lspconfig.pyright.setup({})
			lspconfig.rust_analyzer.setup({})
			vim.keymap.set("n", "K", vim.lsp.buf.hover(), {})
		end,
	},
}
