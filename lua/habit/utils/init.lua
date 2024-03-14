-- various util functions to use in this config
-- loaded with `local utils = require "habit.utils"`

local M = {}

-- call function if condition is met
---@param func function the function to run
---@param condition boolean whether to run function or not
---@return any|nil result the result of function running or nil
function M.conditional_func(func, condition, ...)
  if condition and type(func) == "function" then return func(...) end
end

-- get an empty table of mappings with a key for each map mode
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

-- merge extended options with a default table of options
---@param default? table the default table that you want to merge into
---@param opts? table the new options that should be merged with the default table
---@return table # the merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

-- get an icon from the internal icons if it is available & return it
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

-- get highlight properties for a given highlight name
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

-- get icon spinner table if available in icons. in format `kind1`, `kind2`, `kind3`, ...
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

-- check if plugin is defined in lazy. useful with lazy loading when plugins are not necessary loaded yet
---@param plugin string the plugin to search for
---@return boolean available whether the plugin is available
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

-- serve notification
---@param msg string the notification body
---@param type? number the type of notification (:help vim.log.levels)
function M.notify(msg, type)
  vim.schedule(function() vim.notify(msg, type) end)
end

-- open a url under cursor with current os
---@param path string the path of the file to open with system opener
function M.system_open(path)
  if vim.ui.open then return vim.ui.open(path) end
  local cmd
  if vim.fn.has "mac" == 1 then
    cmd = { "open" }
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

-- create button entity to use with alpha dashboard
---@param sc string the string we want to bind to a key
---@param txt string the tooltip for the keybinding
---@return table # a button entity table for an alpha config
function M.alpha_button(sc, txt)
  -- replace <leader> in shortcut text with LDR for nicer printing
  local sc_ = sc:gsub("%s", ""):gsub("LDR", "<Leader>")
  -- if leader is set, replace text w actual leader key for nicer printing
  if vim.g.mapleader then sc = sc:gsub("<leader>", vim.g.mapleader == " " and "SPC" or vim.g.mapleader) end
  return {
    type = "button",
    val = txt,
    on_press = function()
      local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
      vim.api.nvim_feedkeys(key, "normal", false)
    end,
    opts = {
      position = "center",
      text = txt,
      shortcut = sc,
      cursor = -2,
      width = 36,
      align_shortcut = "right",
      hl = "DashboardCenter",
      hl_shortcut = "DashboardShortcut",
    },
  }
end

-- resolve opts table for given plugin w lazy
---@param plugin string the plugin to search for
---@return table opts the plugin opts
function M.plugin_opts(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  local lazy_plugin_avail, lazy_plugin = pcall(require, "lazy.core.plugin")
  local opts = {}
  if lazy_config_avail and lazy_plugin_avail then
    local spec = lazy_config.spec.plugins[plugin]
    if spec then opts = lazy_plugin.values(spec, "opts") end
  end
  return opts
end

-- wrap a module function to require a plugin before running
---@param plugin string the plugin to call `require("lazy").load` with
---@param module table the system module where the functions live (e.g. `vim.ui`)
---@param func_names string|string[] the functions to wrap in the given module (e.g. `{ "ui", "select" }`)
function M.load_plugin_with_func(plugin, module, func_names)
  if type(func_names) == "string" then func_names = { func_names } end
  for _, func in ipairs(func_names) do
    local old_func = module[func]
    module[func] = function(...)
      module[func] = old_func
      require("lazy").load { plugins = { plugin } }
      module[func](...)
    end
  end
end

-- register queued which-key mappings
function M.which_key_register()
  if M.which_key_queue then
    local wk_avail, wk = pcall(require, "which-key")
    if wk_avail then
      for mode, registration in pairs(M.which_key_queue) do
        wk.register(registration, { mode = mode })
      end
      M.which_key_queue = nil
    end
  end
end

-- table based api for setting keybindings
---@param map_table table a nested table where key 1 is mode, key 2 is key to map, & value is function to which we set the mapping
---@param base? table a base set of opts to set on every keybinding
function M.set_mappings(map_table, base)
  -- iterate over 1st keys for each mode
  base = base or {}
  for mode, maps in pairs(map_table) do
    -- iterate over each keybinding set in current mode
    for keymap, opts in pairs(maps) do
      -- build opts for command accordingly
      if opts then
        local cmd = opts
        local keymap_opts = base
        if type(opts) == "table" then
          cmd = opts[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, opts)
          keymap_opts[1] = nil
        end
        if not cmd or keymap_opts.name then -- if which-key mapping, queue it
          if not keymap_opts.name then keymap_opts.name = keymap_opts.desc end
          if not M.which_key_queue then M.which_key_queue = {} end
          if not M.which_key_queue[mode] then M.which_key_queue[mode] = {} end
          M.which_key_queue[mode][keymap] = keymap_opts
        else -- if not which-key mapping, set it
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end
  if package.loaded["which-key"] then M.which_key_register() end -- if which-key is loaded already, register
end

-- regex used for matching valid url/uri string
M.url_matcher = "\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*})\\})+"

-- delete syntax matching rules for urls/uris if set
function M.delete_url_match()
  for _, match in ipairs(vim.fn.getmatches()) do
    if match.group == "HighlightURL" then vim.fn.matchdelete(match.id) end
  end
end

-- add syntax matching rules for highlighting urls/uris
function M.set_url_match()
  M.delete_url_match()
  if vim.g.highlighturl_enabled then vim.fn.matchadd("HighlightURL", M.url_matcher, 15) end
end

-- run a shell command, capture output & if command succeeded
---@param cmd string|string[] the terminal command to execute
---@return string|nil result the result of a successfully executed command or nil
function M.cmd(cmd)
  if type(cmd) == "string" then cmd = { cmd } end
  local result = vim.fn.system(cmd)
  local success = vim.api.nvim_get_vvar "shell_error" == 0
  if not success then
    vim.api.nvim_err_writeln(("Error runing command %s\nError message:\n%s"):format(table.concat(cmd, " "), result))
  end
  return success and result:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "") or nil
end

return M
