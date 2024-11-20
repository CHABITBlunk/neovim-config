return {
	"nvim-neo-tree/neo-tree.nvim",
	specs = {
		{ "nvim-lua/plenary.nvim", lazy = true },
		{ "MunifTanjim/nui.nvim",  lazy = true },
		{
			"AstroNvim/astrocore",
			opts = function(_, opts)
				local maps = opts.mappings
				maps.n["<C-e>"] = { "<Cmd>Neotree toggle <CR>", desc = "toggle neo-tree" }
				maps.n["<C-o>"] = {
					function()
						if vim.bo.filetype == "neo-tree" then
							vim.cmd.wincmd("p")
						else
							vim.cmd.Neotree("focus")
						end
					end,
					desc = "toggle neo-tree focus",
				}
				opts.autocmds.neotree_start = {
					{
						event = "BufEnter",
						desc = "open neo-tree on startup with dir",
						callback = function()
							if package.loaded("neo-tree") then
								return true
							else
								local stats = (vim.uv or vim.loop).fs_stat(vim.api.nvim_buf_get_name(0))
								if stats and stats.type == "directory" then
									require("lazy").load({ plugins = { "neo-tree.nvim" } })
									return true
								end
							end
						end,
					},
				}
			end,
		},
		cmd = "Neotree",
		opts_extend = { "sources" },
		opts = function()
			local astro, get_icon = require("astrocore"), require("astroui").get_icon
			local git_available = vim.fn.executable("git") == 1
			local sources = {
				{ source = "filesystem", display_name = get_icon("FolderClosed", 1, true) .. "File" },
			}
			local opts = {
				enable_git_status = git_available,
				auto_clean_after_session_restore = true,
				close_if_last_window = true,
				sources = { "filesystem" },
				source_selector = {
					winbar = true,
					content_layout = "center",
					sources = sources,
				},
				default_component_configs = {
					indent = {
						padding = 0,
						expander_collapsed = get_icon("FoldClosed"),
						expander_expanded = get_icon("FoldOpened"),
					},
					icon = {
						folder_closed = get_icon("FolderClosed"),
						folder_open = get_icon("FolderOpen"),
						folder_empty = get_icon("FolderEmpty"),
						folder_empty_open = get_icon("FolderEmpty"),
						default = get_icon("DefaultFile"),
					},
					modified = { symbol = get_icon("FileModified") },
					git_status = {
						symbols = {
							added = get_icon("GitAdd"),
							deleted = get_icon("GitDelete"),
							modified = get_icon("GitChange"),
							renamed = get_icon("GitRenamed"),
							untracked = get_icon("GitUntracked"),
							ignored = get_icon("GitIgnored"),
							unstaged = get_icon("GitUnstaged"),
							staged = get_icon("GitStaged"),
							conflict = get_icon("GitConflict"),
						},
					},
				},
				commands = {
					system_open = function(state)
						-- TODO: remove deprecated method check after switching to v0.9+
						(vim.ui.open or astro.system_open)(state.tree:get_node():get_id())
					end,
					parent_or_close = function(state)
						local node = state.tree:get_node()
						if node:has_children() and node:is_expandable() then
							state.commands.toggle_node(state)
						else
							require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
						end
					end,
					child_or_open = function(state)
						local node = state.tree:get_node()
						if node:has_children() then
							if not node:is_expanded() then
								state.commands.toggle_node(state)
							else
								if node.type == "file" then
									state.commands.open(state)
								else
									require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
								end
							end
						else
							state.commands.open(state)
						end
					end,
					copy_selector = function(state)
						local node = state.tree:get_node()
						local filepath = node:get_id()
						local filename = node.name
						local modify = vim.fn.fnamemodify
						local vals = {
							["BASENAME"] = modify(filename, ":r"),
							["EXTENSION"] = modify(filename, ":e"),
							["FILENAME"] = filename,
							["PATH (CWD)"] = modify(filepath, ":."),
							["PATH (HOME)"] = modify(filepath, ":~"),
							["PATH"] = filepath,
							["URI"] = vim.uri_from_fname(filepath),
						}

						local options = vim.tbl_filter(function(val)
							return vals[val] ~= ""
						end, vim.tbl_keys(vals))
						if vim.tbl_isempty(options) then
							astro.notify("no values to copy", vim.log.levels.WARN)
							return
						end
						table.sort(options)
						vim.ui.select(options, {
							prompt = "choose to copy to clipboard:",
							format_item = function(item)
								return ("%s: %s"):format(item, vals[item])
							end,
						}, function(choice)
							local result = vals[choice]
							if result then
								astro.notify(("copied %s"):format(result))
								vim.fn.setreg("+", result)
							end
						end)
					end,
				},
				window = {
					width = 30,
					mappings = {
						O = "system_open",
						Y = "copy_selector",
						h = "parent_or_close",
						l = "child_or_open",
					},
					fuzzy_finder_mappings = {
						["<C-J>"] = "move_cursor_down",
						["<C-K>"] = "move_cursor_up",
					},
				},
				filesystem = {
					follow_current_file = { enabled = true },
					filtered_items = { hide_gitignored = git_available },
					hijack_netrw_behavior = "open_current",
					use_libuv_file_watcher = vim.fn.has("win32") ~= 1,
				},
				event_handlers = {
					{
						event = "neo_tree_buffer_enter",
						handler = function(_)
							vim.opt_local.signcolumn = "auto"
							vim.opt_local.foldcolumn = "0"
						end,
					},
				},
			}

			if astro.is_available("telescope.nvim") then
				opts.commands.find_in_dir = function(state)
					local node = state.tree:get_node()
					local path = node.type == "file" and node:get_parent_id() or node:get_id()
					require("telescope.builtin").find_files({ cwd = path })
				end
				opts.window.mappings.F = "find_in_dir"
			end

			return opts
		end,
	},
}
