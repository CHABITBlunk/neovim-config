--- status highlighting
--
-- statusline related highlighting utilities
--
-- loaded with `local hl = require "habit.utils.status.hl"`

local M = {}

local env = require "habit.utils.status.env"

--- get foreground color group for current filetype
---@return table # the highlight group for the current filetype foreground
---@usage local heirline_component = { provider = require("habit.utils.status").provider.fileicon(), hl = require("habit.utils.status").hl.filetype_color },
function M.filetype_color(self)
  local devicons_avail, devicons = pcall(require, "nvim-web-devicons")
  if not devicons_avail then return {} end
  local _, color = devicons.get_icon_color(
    vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self and self.bufnr or 0), ":t"),
    nil,
    { default = true }
  )
  return { fg = color }
end

--- enable filetype color highlight if enabled in icon_highlights.file_icon options
---@param name string the icon_highlights.file_icon table element
---@return function # for setting hl property in a component
---@usage local heirline_component = { provider = "Example Provider", hl = require("habit.utils.status").hl.file_icon("winbar") },
function M.file_icon(name)
  local hl_enabled = env.icon_highlights.file_icon[name]
  return function(self)
    if hl_enabled == true or (type(hl_enabled) == "function" and hl_enabled(self))  then
      return M.filetype_color(self)
    end
  end
end

--- merge color & attributes from user settings for a given name
---@param name string the name of the element to get the attributes and colors for
---@param include_bg? boolean whether or not to include the background color (default: false)
---@return table hl a table of highlight info
---@usage local heirline_component = { provider = "Example Provider", hl = require("habit.utils.status").hl.get_attributes("treesitter") },
function M.get_attributes(name, include_bg)
  local hl = env.attributes[name] or {}
  hl.fg = name .. "_fg"
  if include_bg then hl.bg = name .. "_bg" end
  return hl
end

--- get highlight background color of lualine theme for current colorscheme
---@param mode string the neovim mode to get the color of
---@param fallback string the color to fall back on if a lualine theme is not present
---@return string the background color of the lualine theme or the fallback parameter if one doesn't exist
function M.lualine_mode(mode, fallback)
  if not vim.g.colors_name then return fallback end
  local lualine_avail, lualine = pcall(require, "lualine.themes." .. vim.g.colors_name)
  local lualine_opts = lualine_avail and lualine[mode]
  return lualine_opts and type(lualine_opts.a) == "table" and lualine_opts.a.bg or fallback
end

--- get highlight for current mode
---@return table # the highlight group for the current mode
---@usage local heirline_component = { provider = "Example Provider", hl = require("habit.utils.status").hl.mode },
function M.mode() return { bg = M.mode_bg() }end

--- get foreground color group for current mode, good for usage with heirline surround utility
---@return string # the highlight group for current filetype foreground
---@usage local heirline_component = require("heirline.utils").surround({ "|", "|" }, require("habit.utils.status").hl.mode_bg, heirline_component),
function M.mode_bg() return env.modes[vim.fn.mode()][2] end

return M
