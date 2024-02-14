-- various util functions to use in this config
-- loaded with `local utils = require "habit.utils"`

local M = {}

--- call function if condition is met
---@param func function the function to run
---@param condition boolean whether to run function or not
---@return any|nil result the result of function running or nil
function M.conditional_func(func, condition, ...)
  if condition and type(func) == "function" then return func(...) end
end

--- get an empty table of mappings with a key for each map mode
---@return table<string,table> # a table with entries for each map mode
function M.empty_map_table()
  local maps = {}
  for _, abbr_mode in ipairs { "", "n", "v", "x", "s", "o", "!", "i", "l", "c", "t" } do
    maps[abbr_mode] = {}
  end
  if vim .fn.has "nvim-0.10.0" == 1 then
    for _, abbr_mode in ipairs { "ia", "ca", "!a" } do
      maps[abbr_mode] = {}
    end
  end
  return maps
end

-- trigger a user event
---@param event string the event name to be appended to habit
---@param delay? boolean whether or not to delay event asynchronously (default is true)
function M.event(event, delay)
  local emit_event = function() vim.api.nvim_exec_autocmds("User", { pattern = "Habit" .. event, modeline = false }) end
  if delay == false then
    emit_event()
  else
    vim.schedule(emit_event)
  end
end

--- merge extended options with a default table of options
---@param default? table the default table that you want to merge into
---@param opts? table the new options that should be merged with the default table
---@return table # the merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- get an icon from the internal icons if it is available & return it
---@param kind string the kind of icon in habit.icons to retrieve
---@param padding? integer padding to add to end of icon
---@param no_fallback? boolean whether or not to disable fallback to text icon
---@return string # icon
function M.get_icon(kind, padding, no_fallback)
  if no_fallback then return "" end
  local icon_pack = "icons" or "text_icons"
  if not M[icon_pack] then
    M.icons = require "habit.icons.nerd_font"
    M.text_icons = require "habit.icons.text"
  end
  local icon = M[icon_pack] and M[icon_pack][kind]
  return icon and icon .. string.rep(" ", padding or 0) or ""
end

--- get highlight properties for a given highlight name
---@param name string the highlight group name
---@param fallback? table the fallback highlight properties
---@return table properties the highlight group properties
function M.get_hlgroup(name, fallback)
  if vim.fn.hlexists(name) == 1 then
    local hl
    if vim.api.nvim_get_hl then -- check for neovim 0.9 api
      hl= vim.api.nvim_get_hl(0, { name = name, link = false })
      if not hl.fg then hl.fg = "NONE" end
      if not hl.bg then hl.bg = "NONE" end
    else
      hl = vim.api.get_hl_by_name(name, vim.o.termguicolors)
      if not hl.foreground then hl.foreground = "NONE" end
      if not hl.background then hl.background = "NONE" end
      hl.fg, hl.bg = hl.foreground, hl.background
      hl.ctermfg, hl.ctermbg = hl.fg, hl.bg
      hl.sp = hl.special
    end
    return hl
  end
  return fallback or {}
end

--- get icon spinner table if available in icons. in format `kind1`, `kind2`, `kind3`, ...
---@param kind string the kind of icon for which to check sequential entries
---@return string[]|nil spinners a collected table of spinning icons in sequential order or nil if none exist
function M.get_spinner(kind, ...)
  local spinner = {}
  repeat
    local icon = M.get_icon(("%s%d"):format(kind, #spinner + 1), ...)
    if icon ~= "" then table.insert(spinner, icon) end
  until not icon or icon == ""
    if #spinner > 0 then return spinner end
end

--- check if plugin is defined in lazy. useful with lazy loading when plugins are not necessary loaded yet
---@param plugin string the plugin to search for
---@return boolean available whether the plugin is available
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

--- serve notification
---@param msg string the notification body
---@param type? number the type of notification (:help vim.log.levels)
function M.notify(msg, type)
  vim.schedule(function() vim.notify(msg, type) end)
end

--- open a url under cursor with current os
---@param path string the path of the file to open with system opener
function M.system_open(path)
  if vim.ui.open then return vim.ui.open(path) end
  local cmd
  if vim.fn.has "mac" == 1 then
    cmd = { "open" }
  elseif vim.fn.has "win32" == 1 then
    if vim.fn.executable "rundll32" then
      cmd = { "rundll32", "url.dll,FileProtocolHandler" }
    else
      cmd = { "cmd.exe", "/K", "explorer" }
    end
  elseif vim.fn.has "unix" == 1 then
    if vim.fn.executable "wslview" == 1 then
      cmd = { "wslview" }
    elseif vim.fn.executable "xdg-open" == 1 then
      cmd = { "xdg-open" }
    end
  end
  if not path then
    path = vim.fm.expand "<cfile>"
  elseif not path:match "%w+:" then
    path = vim.fn.expand(path)
  end
  vim.fn.jobstart(vim.list_extend(cmd, { path }), { detach = true })
end

return M
