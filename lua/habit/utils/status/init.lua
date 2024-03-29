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

--- an `init` function to build a set of children components for a separated path to file
---@param opts? table opts for configuring the breadcrumbs (default: `{ max_depth = 3, path_func = provider.unique_path(), separator = "  ", suffix = true, padding = { left = 0, right = 0 } }`)
---@return function # the heirline init function
---@usage local heirline_component = { init = require("habit.utils.status").init.separated_path { padding = { left = 1 } } }
function M.separated_path(opts)
  opts = extend_tbl({
    max_depth = 3,
    path_func = provider.unique_path(),
    separator = env.separators.path or  "  ",
    suffix = true,
    padding = { left = 0, right = 0 },
  }, opts)
  if opts.suffix == true then opts.suffix = opts.separator end
  return function(self)
    local path = opts.path_func(self)
    if path == "." then path = "" end -- if there is no path, just replace it with empty string
    local data = vim.fn.split(path, "/")
    local children = {}
    -- add prefix if needed, use separator if true, or use provided char
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
        local child = { { provider = d } }
        local separator = i < #data and opts.separator or opts.suffix
        if separator then table.insert(child, { provider = separator }) end
        table.insert(children, child)
      end
    end
    if opts.padding.left > 0 then -- add left padding
      table.insert(children, 1, { provider = status_utils.pad_string(" ", { left = opts.padding.left - 1}) })
    end
    if opts.padding.right > 0 then -- add right padding
      table.insert(children, 1, { provider = status_utils.pad_string(" ", { right = opts.padding.right - 1}) })
    end
    -- instantiate new child
    self[1] = self:new(children, 1)
  end
end

-- an `init` function to build multiple update events which is not supported yet by heirline's update field
---@param opts any[] an array-like table of autocmd events as either just a string or a table with custom patterns & callbacks
---@return function # the heirline init function
function M.update_events(opts)
  return function(self)
    if not rawget(self, "once") then
      local function clear_cache() self._win_cache = nil end
      for _, event in ipairs(opts) do
        local event_opts = { callback = clear_cache }
        if type(event) == "table" then
          event_opts.pattern = event.pattern
          event_opts.callback = event.callback or clear_cache
          event.pattern = nil
          event.callback = nil
        end
        vim.api.nvim_create_autocmd(event, event_opts)
      end
      self.once = true
    end
  end
end

return M
