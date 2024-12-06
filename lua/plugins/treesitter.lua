return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", lazy = true } },
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"css",
				"lua",
				"go",
				"html",
				"markdown",
				"markdown_inline",
				"java",
				"javascript",
				"python",
				"query",
				"rust",
				"scss",
				"vim",
				"vimdoc",
				"yuck",
			},
			sync_install = false,
		})
	end,
}
