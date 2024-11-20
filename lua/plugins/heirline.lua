return {
	"rebelot/heirline.nvim",
	event = "BufEnter",
	specs = {
		{
			"AstroNvim/astrocore",
			---@param opts AstroCoreOpts
			opts = function(_, opts)
				local maps = opts.mappings
				maps.n["<Leader>bb"] = {
					function()
						require("astroui.status.heirline").buffer_picker(function(bufnr)
							vim.api.nvim_win_set_buf(0, bufnr)
						end)
					end,
					desc = "set buffer from tabline",
				}
				maps.n["<Leader>bd"] = {
					function()
						require("astroui.status.heirline").buffer_picker(function(bufnr)
							require("astrocore.buffer").close(bufnr)
						end)
					end,
					desc = "close buffer from tabline",
				}
				maps.n["<Leader>b\\"] = {
					function()
						require("astroui.status.heirline").buffer_picker(function(bufnr)
							vim.cmd.split()
							vim.api.nvim_win_set_buf(0, bufnr)
						end)
					end,
					desc = "horizontal split buffer from tabline",
				}
				maps.n["<Leader>b|"] = {
					function()
						require("astroui.status.heirline").buffer_picker(function(bufnr)
							vim.cmd.vsplit()
							vim.api.nvim_win_set_buf(0, bufnr)
						end)
					end,
					desc = "vertical split buffer from tabline",
				}
				opts.autocmds.heirline_colors = {
					{
						event = "User",
						pattern = "AstroColorScheme",
						desc = "refresh heirline colors",
						callback = function()
							if package.loaded["heirline"] then
								require("astroui.status.heirline").refresh_colors()
							end
						end,
					},
				}
			end,
		},
	},
	opts = function()
		local status = require("astroui.status")
		local ui_config = require("astroui").config
		return {
			opts = {
				colors = require("astroui").config.status.setup_colors(),
				disable_winbar_cb = function(args)
					local enabled = vim.tbl_get(ui_config, "status", "winbar", "enabled")
					if enabled and status.condition.buffer_matches(enabled, args.buf) then
						return false
					end
					local disabled = vim.tbl_get(ui_config, "status", "winbar", "disabled")
					return not require("astrocore.buffer").is_valid(args.buf)
						or (disabled and status.condition.buffer_matches(disabled, args.buf))
				end,
			},
			statusline = {
				hl = { fg = "fg", bg = "bg" },
				status.component.mode(),
				status.component.git_branch(),
				status.component.file_info(),
				status.component.git_diff(),
				status.component.diagnostics(),
				status.component.fill(),
				status.component.cmd_info(),
				status.component.fill(),
				status.component.lsp(),
				status.component.virtual_env(),
				status.component.treesitter(),
				status.component.nav(),
				status.component.mode({ surround = { separator = "right" } }),
			},
			winbar = {
				init = function(self)
					self.bufnr = vim.api.nvim_get_current_buf()
				end,
				fallthrough = false,
				{
					condition = function()
						return not status.condition.is_active()
					end,
					status.component.separated_path(),
					status.component.file_info({
						file_icon = { hl = status.hl.file_icon("winbar"), padding = { left = 0 } },
						filename = {},
						filetype = false,
						file_read_only = false,
						hl = status.hl.get_attributes("winbarnc", true),
						surround = false,
						update = "BufEnter",
					}),
				},
				status.component.breadcrumbs({ hl = status.hl.get_attributes("winbar", true) }),
			},
			tabline = {
				{
					condition = function(self)
						self.winid = vim.api.nvim_tabpage_list_wins(0)[1]
						self.winwidth = vim.api.nvim_win_get_width(self.winid)
						return self.winwidth ~= vim.o.columns
							and not require("astrocore.buffer").is_valid(vim.api.nvim_win_get_buf(self.winid))
					end,
					provider = function(self)
						return (" "):rep(self.winwidth + 1)
					end,
					hl = { bg = "tabline_bg" },
				},
				status.heirline.make_buflist(status.component.tabline_file_info()),
				status.component.fill({ hl = { bg = "tabline_bg" } }),
				{
					condition = function()
						return #vim.api.nvim_list_tabpages() >= 2
					end,
					status.heirline.make_tablist({
						provider = status.provider.tabnr(),
						hl = function(self)
							return status.hl.get_attributes(status.heirline.tab_type(self, "tab"), true)
						end,
					}),
				},
			},
			statuscolumn = {
				init = function(self)
					self.bufnr = vim.api.nvim_get_current_buf()
				end,
				status.component.foldcolumn(),
				status.component.numbercolumn(),
				status.component.signcolumn(),
			},
		}
	end,
}
