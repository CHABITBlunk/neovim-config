--- status initializers
--
-- statusline related init functions for building dynamic statusline components
--
-- loaede with `local init = require "habit.utils.status.init"`

local M = {}

local env = require "habit.utils.status.env"
local provider = require "habit.utils.status.provider"
local status_utils = require "habit.utils.status.utils"

local utils = require "habit.utils"
local extend_tbl = utils.extend_tbl

--- an `init` function to build a set of children components for lsp breadcrumbs
---@param opts? table opts for configuring breadcrumbs (default: `{ max_depth = 5, separator = "  ", icon = { enabled = true, hl = false }, padding = { left = 0, right = 0 } }`)
---@return function # the heirline init function
---@usage local heirline_component = { init = require("habit.utils.status").init.breadcrumbs { padding = { left = 1 } } }
function M.breadcrumbs(opts)
  opts = extend_tbl({
    max_depth = 5,
    separator = env.separators.breadcrumbs or "  ",
    icon = { enabled = true, hl = env.icon_highlights.breadcrumbs },
    padding = { left = 0, right = 0 },
  }, opts)
  return function(self)
    local data = require("aerial").get_location(true) or {}
    local children = {}
    -- add prefix if needed, use separator if true, or use provided character
    if opts.prefix and not vim.tbl_isempty(data) then
      table.insert(children, { provider = opts.prefix == true and opts.separator or opts.prefix })
    end
    local start_idx = 0
    if opts.max_depth and opts.max_depth > 0 then
      start_idx = #data - opts.max_depth
      if start_idx > 0 then
        table.insert(children, { provider = require("habit.utils").get_icon "Ellipsis" .. opts.separator })
      end
    end
    -- create child for each level
    for i, d in ipairs(data) do
      if i > start_idx then
        local child = {
          { provider = string.gsub(d.name, "%%", "%%%%"):gsub("%s*->%s*", "") }, -- add symbol name
          on_click = { -- add on click function
            minwid = status_utils.encode_pos(d.lnum, d.col, self.winnr),
            callback = function(_, minwid)
              local lnum, col, winnr = status_utils.decode_pos(minwid)
              vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { lnum, col })
            end,
            name = "heirline_breadcrumbs",
          },
        }
        if opts.icon_enabled then
          local hl = opts.icon.hl
          if type(hl) == "function" then hl = hl(self) end
          local hlgroup = string.format("Aerial%sIcon", d.kind)
          table.insert(child, 1, {
            provider = string.format("%s ", d.icon),
            hl = (hl and vim.fn.hlexists(hlgroup) == 1) and hlgroup or nil,
          })
        end
        if #data > 1 and i < #data then table.insert(child, { provider = opts.separator }) end -- add separator only if needed
        table.insert(children, child)
      end
    end
    if opts.padding.left > 0 then
      table.insert(children, 1, { provider = status_utils.pad_string(" ", { left = opts.padding.left - 1}) })
    end
    if opts.padding.right > 0 then
      table.insert(children, { provider = status_utils.pad_string(" ", { right = opts.padding.right - 1}) })
    end
    -- instantiate new child
    self[1] = self:new(children, 1)
  end
end
