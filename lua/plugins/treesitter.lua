return {
	"nvim-treesitter/nvim-treesitter",
	main = "nvim-treesitter.configs",
	dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", lazy = true } },
	event = "User AstroFile",
	cmd = {
		"TSBufDisable",
		"TSBufEnable",
		"TSBufToggle",
		"TSDisable",
		"TSEnable",
		"TSToggle",
		"TSInstall",
		"TSInstallInfo",
		"TSInstallSync",
		"TSModuleInfo",
		"TSUninstall",
		"TSUpdate",
		"TSUpdateSync",
	},
	build = ":TSUpdate",
	init = function(plugin)
		-- PERF: add nvim-treesitter queries to rtp & its custom query predicates early
		-- this is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
		-- no longer trigger the **nvim-treesitter** module to be loaded in time.
		-- luckily, the only things those plugins need are the custom queries, which we make available
		-- during startup.
		-- CODE FROM LazyVim https://github.com/LazyVim/LazyVim/commit/1e1b68d633d4bd4faa912ba5f49ab6b8601dc0c9
		require("lazy.core.loader").add_to_rtp(plugin)
		pcall(require, "nvim-treesitter.query_predicates")
	end,
	opts_extend = { "ensure_installed" },
	opts = function()
		if require("astrocore").is_available("mason.nvim") then
			require("lazy").load({ plugins = { "mason.nvim" } })
		end
		return {
			auto_install = vim.fn.executable("git") == 1 and vim.fn.executable("tree-sitter") == 1,
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
				"python",
				"query",
				"rust",
				"scss",
				"vim",
				"vimdoc",
				"yuck",
			},
			highlight = { enable = true },
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["ak"] = { query = "@block.outer", desc = "around block" },
						["ik"] = { query = "@block.inner", desc = "inside block" },
						["ac"] = { query = "@class.outer", desc = "around class" },
						["ic"] = { query = "@class.inner", desc = "inside class" },
						["a?"] = { query = "@conditional.outer", desc = "around conditional" },
						["i?"] = { query = "@conditional.inner", desc = "inside conditional" },
						["af"] = { query = "@function.outer", desc = "around function" },
						["if"] = { query = "@function.inner", desc = "inside function" },
						["ao"] = { query = "@loop.outer", desc = "around loop" },
						["io"] = { query = "@loop.inner", desc = "inside loop" },
						["aa"] = { query = "@parameter.outer", desc = "around parameter" },
						["ia"] = { query = "@parameter.inner", desc = "inside parameter" },
					},
				},
				move = {
					enable = true,
					set_jumps = true,
					goto_next_start = {
						["]k"] = { query = "@block.outer", desc = "next block start" },
						["]f"] = { query = "@function.outer", desc = "next function start" },
						["]a"] = { query = "@parameter.inner", desc = "next parameter start" },
					},
					goto_next_end = {
						["]K"] = { query = "@block.outer", desc = "next block end" },
						["]F"] = { query = "@function.outer", desc = "next function end" },
						["]A"] = { query = "@parameter.inner", desc = "next parameter end" },
					},
					goto_previous_start = {
						["[k"] = { query = "@block.outer", desc = "previous block start" },
						["[f"] = { query = "@function.outer", desc = "previous function start" },
						["[a"] = { query = "@parameter.inner", desc = "previous parameter start" },
					},
					goto_previous_end = {
						["[K"] = { query = "@block.outer", desc = "previous block end" },
						["[F"] = { query = "@function.outer", desc = "previous function end" },
						["[A"] = { query = "@parameter.inner", desc = "previous parameter end" },
					},
				},
				swap = {
					enable = true,
					swap_next = {
						[">K"] = { query = "@block.outer", desc = "swap next block" },
						[">F"] = { query = "@function.outer", desc = "swap next function" },
						[">A"] = { query = "@parameter.inner", desc = "swap next parameter" },
					},
					swap_previous = {
						["<K"] = { query = "@block.outer", desc = "swap previous block" },
						["<F"] = { query = "@function.outer", desc = "swap previous function" },
						["<A"] = { query = "@parameter.inner", desc = "swap previous parameter" },
					},
				},
			},
		}
	end,
	config = function(plugin, opts)
		local ts = require(plugin.main)
		if vim.fn.executable("git") == 0 then
			opts.ensure_installed = nil
		end

		-- disable all treesitter modules on large buffer
		if vim.tbl_get(require("astrocore").config, "features", "large_buf") then
			for _, module in ipairs(ts.available_modules()) do
				if not opts[module] then
					opts[module] = {}
				end
				local module_opts = opts[module]
				local disable = module_opts.disable
				module_opts.disable = function(lang, bufnr)
					return vim.b[bufnr].large_buf
						or (type(disable) == "table" and vim.tbl_contains(disable, lang))
						or (type(disable) == "function" and disable(lang, bufnr))
				end
			end
		end

		ts.setup(opts)
	end,
}
