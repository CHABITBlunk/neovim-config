return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local t = require("telescope.builtin")
		vim.keymap.set("n", "<leader>f<CR>", t.marks, {})
		vim.keymap.set("n", "<leader>f'", t.marks, {})
		vim.keymap.set("n", "<leader>f/", t.current_buffer_fuzzy_find, {})
		vim.keymap.set("n", "<leader>fa", function()
			t.find_files({
				prompt_title = "config files",
				cwd = vim.fn.stdpath("config"),
				follow = true,
			})
		end, {})
		vim.keymap.set("n", "<leader>fb", t.buffers, {})
		vim.keymap.set("n", "<leader>fc", t.grep_string, {})
		vim.keymap.set("n", "<leader>fC", t.commands, {})
		vim.keymap.set("n", "<leader>ff", t.find_files, {})
		vim.keymap.set("n", "<leader>fF", t.find_files({ hidden = true, no_ignore = true }), {})
		vim.keymap.set("n", "<leader>fh", t.help_tags, {})
		vim.keymap.set("n", "<leader>fk", t.keymaps, {})
		if vim.fn.executable("rg") == 1 then
			vim.keymap.set("n", "<leader>fw", t.live_grep)
			vim.keymap.set("n", "<leader>fW", function()
				t.live_grep({
					additional_args = function(args)
						return vim.list_extend(args, { "--hidden", "--no-ignore" })
					end,
				})
			end)
		end
		vim.keymap.set("n", "<leader>lD", t.diagnostics, {})
	end,
}
