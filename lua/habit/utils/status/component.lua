-- status components
--
-- statusline related component functions to use with heirline
--
-- loaded with `local component = require "habit.utils.status.component"`

local M = {}

local condition = require "habit.utils.status.condition"
local hl = require "habit.utils.status.hl"
local init = require "habit.utils.status.init"
local provider = require "habit.utils.status.provider"
local status_utils = require "habit.utils.status.utils"

local utils = require "habit.utils"
local extend_tbl = utils.extend_tbl

-- a heirline component for filling in empty space of bar
---@param opts? table options for configuring other fields of heirline component
---@return table # the heirline component table
function M.fill(opts) return extend_tbl({ provider = provider.fill() }, opts) end

-- a function to build a set of children components for an entire file info section
---@param opts? table options for configuring other fields of heirline component
---@return table # the heirline component table
function M.file_info(opts)
  opts = extend_tbl({
    file_icon = { hl = hl.file_icon "statusline", padding = { left = 1, right = 1 } },
    filename = {},
    file_modified = { padding = { left = 1 } },
    file_read_only = { padding = { left = 1 } },
    surround = { separator = "left", color = "file_info_bg", condition = condition.has_filetype },
    hl = hl.get_attributes "file_info",
  }, opts)
  return M.builder(status_utils.setup_providers(opts, {
    "file_icon",
    "unique_path",
    "filename",
    "file_modified",
    "file_read_only",
    "close_button",
  }))
end

-- a function with different file_info default specifically for tabline
---@param opts? table options for configuring file_icon, filename, filetype, file_modified, file_read_only, & overall padding
---@return table # the heirline component table
function M.tabline_file_info(opts)
  return M.file_info(extend_tbl({
    file_icon = {
      condition = function(self) return not self._show_picker end,
      hl = hl.file_icon "tabline",
    },
    unique_path = {
      hl = function(self) return hl.get_attributes(self.tab_type .. "_path") end,
    },
    close_button = {
      hl = function(self) return hl.get_attributes(self.tab_type .. "_close") end,
      padding = { left = 1, right = 1 },
    },
    padding = { left = 1, right = 1 },
    hl = function(self)
      local tab_type = self.tab_type
      if self._show_picker and self.tab_type ~= "buffer_active" then tab_type = "buffer_visible" end
      return hl.get_attributes(tab_type)
    end,
    surround = false,
  }, opts))
end

-- a function to build a set of children components for an entire navigation section
---@param opts? table options for configuring ruler, percentage, scrollbar, & overall padding
---@return table #the heirline component table
function M.nav(opts)
  opts = extend_tbl({
    ruler = {},
    percentage = { padding = { left = 1 } },
    scrollbar = { padding = { left = 1 }, hl = { fg = "scrollbar" } },
    surround = { separator = "right", color = "nav_bg" },
    hl = hl.get_attributes "nav",
    update = { "CursorMoved", "CursorMovedI", "BufEnter" },
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "ruler", "percentage", "scrollbar" }))
end

-- a function to build a set of children components for info shown in cmdline
---@param opts? table options for configuring macro recording, search count, & overall padding
---@return table # the heirline component table
function M.cmd_info(opts)
  opts = extend_tbl({
    macro_recording = {
      icon = { kind = "MacroRecording", padding = { right = 1 } },
      condition = condition.is_macro_recording,
      update = {
        "RecordingEnter",
        "RecordingLeave",
        callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
      },
    },
    search_count = {
      icon = { kind = "Search", padding = { right = 1 } },
      padding = { left = 1 },
      condition = condition.is_hlsearch,
    },
    showcmd = {
      padding = { left = 1 },
      condition = condition.is_statusline_showcmd,
    },
    surround = {
      separator = "center",
      color = "cmd_info_bg",
      condition = function()
        return condition.is_hlsearch() or condition.is_macro_recording() or condition.is_statusline_showcmd()
      end
    },
    condition = function() return vim.opt.cmdheight:get() == 0 end,
    hl = hl.get_attributes "cmd_info",
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "macro_recording", "search_count", "showcmd" }))
end

-- a function to build a set of children components for a mode section
---@param opts? table options for configuring mode_text, paste, spell, & overall padding
---@return table # heirline component table
function M.mode(opts)
  opts = extend_tbl({
    mode_text = false,
    paste = false,
    spell = false,
    surround = { separator = "left", color = hl.mode_bg },
    hl = hl.get_attributes "mode",
    update = {
      "ModeChanged",
      pattern = "*:*",
      callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
    },
  }, opts)
  if not opts["mode_text"] then opts.str = { str = " " } end
  return M.builder(status_utils.setup_providers(opts, { "mode_text", "str", "paste", "spell" }))
end

-- a function to build a set of children components for an lsp breadcrumbs section
---@param opts? table options for configuring breadcrumbs & overall padding
---@return table # the heirline component table
function M.breadcrumbs(opts)
  opts = extend_tbl({ padding = { left = 1 }, condition = condition.aerial_available, update = "CursorMoved" }, opts)
  opts.init = init.breadcrumbs(opts)
  return opts
end

-- a function to build a set of children components for the current file path
---@param opts? table options for configuring breadcrumbs & overall padding
---@return table # the heirline component table
function M.separated_path(opts)
  opts = extend_tbl({ padding = { left = 1 }, update = { "BufEnter", "DirChanged" } }, opts)
  opts.init = init.separated_path(opts)
  return opts
end

-- a function to build a set of children components for a git branch section
---@param opts? table options for configuring git branch & overall padding
---@return table # heirline component table
function M.git_branch(opts)
  opts = extend_tbl({
    git_branch = { icon = { kind = "GitBranch", padding = { right = 1 } } },
    surround = { separator = "left", color = "git_branch_bg", condition = condition.is_git_repo },
    hl = hl.get_attributes "git_branch",
    update = { "User", pattern = "GitSignsUpdate" },
    init = init.update_events { "BufEnter" },
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "git_branch" }))
end

-- a function to build a set of children components for a git difference section
---@param opts? table options for configuring git changes & overall padding
---@return table # the heirline component table
function M.git_diff(opts)
  opts = extend_tbl({
    added = { icon = { kind = "GitAdd", padding = { left = 1, right = 1 } } },
    changed = { icon = { kind = "GitChange", padding = { left = 1, right = 1 } } },
    removed = { icon = { kind = "GitDelete", padding = { left = 1, right = 1 } } },
    hl = hl.get_attributes "git_diff",
    surround = { separator = "left" , color = "git_diff_bg", condition = condition.git_changed },
    update = { "User", pattern = "GitSignsUpdate" },
    init = init.update_events { "BufEnter" },
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "added", "changed", "removed" }, function(p_opts, p)
    local out = status_utils.build_provider(p_opts, p)
    if out then
      out.provider = "git_diff"
      out.opts.type = p
      if out.hl == nil then out.hl = { fg = "git_" .. p }end
    end
    return out
  end))
end

-- a function to build a set of children components for a diagnostics section
---@param opts? table opts for configuring diagnostic providers & overall padding
---@return table # the heirline component table
function M.diagnostics(opts)
  opts = extend_tbl({
    ERROR = { icon = { kind = "DiagnosticError", padding = { left = 1, right = 1 } } },
    WARN = { icon = { kind = "DiagnosticWarn", padding = { left = 1, right = 1 } } },
    INFO = { icon = { kind = "DiagnosticInfo", padding = { left = 1, right = 1 } } },
    HINT = { icon = { kind = "DiagnosticHint", padding = { left = 1, right = 1 } } },
    surround = { separator = " left", color = "diagnostics_bg", condition = condition.has_diagnostics },
    hl = hl.get_attributes "diagnostics",
    update = { "DiagnosticChanged", "BufEnter" },
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "ERROR", "WARN", "INFO", "HINT" }, function(p_opts, p)
    local out = status_utils.build_provider(p_opts, p)
    if out then
      out.provider = "diagnostics"
      out.opts.severity = p
      if out.hl == nil then out.hl = { fg = "diag_" .. p } end
    end
    return out
  end))
end

-- a function to build a set of children components for a treesitter section
---@param opts? table options for configuring diagnostic providers & overall padding
---@return table # the heirline component table
function M.treesitter(opts)
  opts = extend_tbl({
    str = { str = "TS", icon = { kind = "ActiveTS", padding = { right = 1 } } },
    surround = {
      separator = "right",
      color = "treesitter_bg",
      condition = condition.treesitter_available,
    },
    hl = hl.get_attributes "treesitter",
    update = { "OptionSet", pattern = "syntax" },
    init = init.update_events { "BufEnter" },
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "str" }))
end

-- a function to build a set of children components for an lsp section
---@param opts? table options for configuring lsp progress & client_name providers & overall padding
---@return table # the heirline component table
function M.lsp(opts)
  opts = extend_tbl({
    lsp_progress = {
      str = "",
      padding = { right = 1 },
      update = {
        "User",
        pattern = "LspProgress",
        callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
      },
    },
    lsp_client_names = {
      str = "LSP",
      update = {
        "LspAttach",
        "LspDetach",
        "BufEnter",
        callback = vim.schedule_wrap(function() vim.cmd.redrawstatus() end),
      },
      icon = { kind = "ActiveLSP", padding = { right = 2 } },
    },
    hl = hl.get_attributes "lsp",
    surround = { separator = "right", color = "lsp_bg", condition = condition.lsp_attached },
  }, opts)
  return M.builder(status_utils.setup_providers(
    opts,
    { "lsp_progress", "lsp_client_names" },
    function(p_opts, p, i)
      return p_opts
        and {
          flexible = i,
          status_utils.build_provider(p_opts, provider[p](p_opts)),
          status_utils.build_provider(p_opts, provider.str(p_opts)),
        }
        or false
    end
  ))
end

-- a function to build a set of components for a foldcolumn section in a statuscolumn
---@param opts? table options for configuring foldcolumn & overall padding
---@return table # the heirline component table
function M.foldcolumn(opts)
  opts = extend_tbl({
    foldcolumn = { padding = { right = 1 } },
    condition = condition.foldcolumn_enabled,
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "foldcolumn" }))
end

-- a function to build a set of components for a numbercolumn section in statuscolumn
---@param opts? table options for configuring signcolumn & overall padding
---@return table # the heirline component table
function M.numbercolumn(opts)
  opts = extend_tbl({
    numbercolumn = { padding = { right = 1 } },
    condition = condition.numbercolumn_enabled,
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "numbercolumn" }))
end

-- a function to build a set of components for a signcolumn section in statuscolumn
---@param opts? table opts for configuring signcolumn & overall padding
---@return table # the heirline component table
function M.signcolumn(opts)
  opts = extend_tbl({
    signcolumn = {},
    condition = condition.signcolumn_enabled,
  }, opts)
  return M.builder(status_utils.setup_providers(opts, { "signcolumn" }))
end

-- a general function to build a section of status providers with highlights, conditions, & section surrounding
---@param opts? table a list of components to build into a section
---@return table # the heirline component table
function M.builder(opts)
  opts = extend_tbl({ padding = { left = 0, right = 0 } }, opts)
  local children = {}
  if opts.padding.left > 0 then -- add left padding
    table.insert(children, { provider = status_utils.pad_string(" ", { left = opts.padding.left - 1 }) })
  end
  for key, entry in pairs(opts) do
    if
      type(key) == "number"
      and type(entry) == "table"
      and provider[entry.provider]
      and (entry.opts == nil or type(entry.otps) == "table")
    then
      entry.provider = provider[entry.provider](entry.opts)
    end
    children[key] = entry
  end
  if opts.padding.right > 0 then -- add right padding
    table.insert(children, { provider = status_utils.pad_string(" ", { right = opts.padding.right - 1 }) })
  end
  return opts.surround
    and status_utils.surround(opts.surround.separator, opts.surround.color, children, opts.surround.condition)
    or children
end

return M
