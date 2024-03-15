-- status environment
--
-- statusline related environment vars shared between components/providers/&c.
-- load with `local env = require "habit.utils.status.env"`

local M = {}

M.fallback_colors = {
  none          = "NONE",
  fg            = "#dcd7ba",
  bg            = "#1f1f28",
  dark_bg       = "#16161d",
  blue          = "#7e9cd8",
  green         = "#98bb6c",
  grey          = "#54546d",
  bright_grey   = "#717c7c",
  dark_grey     = "#363646",
  orange        = "#ffa066",
  purple        = "#938aa9",
  bright_purple = "#957fb8",
  red           = "#c34043",
  bright_red    = "#e82424",
  white         = "#fdf8cb",
  yellow        = "#dca561",
  bright_yellow = "#e6c384",
}

M.modes = {
  ["n"] = { "NORMAL", "normal" },
  ["no"] = { "OP", "normal" },
  ["nov"] = { "OP", "normal" },
  ["noV"] = { "OP", "normal" },
  ["no"] = { "OP", "normal" },
  ["niI"] = { "NORMAL", "normal" },
  ["niR"] = { "NORMAL", "normal" },
  ["niV"] = { "NORMAL", "normal" },
  ["i"] = { "INSERT", "insert" },
  ["ic"] = { "INSERT", "insert" },
  ["ix"] = { "INSERT", "insert" },
  ["t"] = { "TERM", "terminal" },
  ["nt"] = { "TERM", "terminal" },
  ["v"] = { "VISUAL", "visual" },
  ["vs"] = { "VISUAL", "visual" },
  ["V"] = { "LINES", "visual" },
  ["Vs"] = { "LINES", "visual" },
  [""] = { "BLOCK", "visual" },
  ["s"] = { "BLOCK", "visual" },
  ["R"] = { "REPLACE", "replace" },
  ["Rc"] = { "REPLACE", "replace" },
  ["Rx"] = { "REPLACE", "replace" },
  ["Rv"] = { "V-REPLACE", "replace" },
  ["s"] = { "SELECT", "visual" },
  ["S"] = { "SELECT", "visual" },
  [""] = { "BLOCK", "visual" },
  ["c"] = { "COMMAND", "command" },
  ["cv"] = { "COMMAND", "command" },
  ["ce"] = { "COMMAND", "command" },
  ["r"] = { "PROMPT", "inactive" },
  ["rm"] = { "MORE", "inactive" },
  ["r?"] = { "CONFIRM", "inactive" },
  ["!"] = { "SHELL", "inactive" },
  ["null"] = { "null", "inactive" },
}

M.separators = {
  none = { "", "" },
  left = { "", "  " },
  right = { "  ", "" },
  center = { "  ", "  " },
  tab = { "", " " },
  breadcrumbs = "  ",
  path = "  ",
}

M.attributes = {
  buffer_active = { bold = true, italic = true },
  buffer_picker = { bold = true },
  macro_recording = { bold = true },
  git_branch = { bold = true },
  git_diff = { bold = true },
}

M.icon_highlights = {
  file_icon = {
    tabline = function(self) return self.is_active or self.is_visible end,
    statusline = true,
  },
}

local function pattern_match(str, pattern_list)
  for _, pattern in ipairs(pattern_list) do
    if str:find(pattern) then return true end
  end
  return false
end

M.buf_matchers = {
  filetype = function(pattern_list, bufnr) return pattern_match(vim.bo[bufnr or 0].filetype, pattern_list) end,
  buftype = function(pattern_list, bufnr) return pattern_match(vim.bo[bufnr or 0].buftype, pattern_list) end,
  bufname = function(pattern_list, bufnr)
    return pattern_match(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr or 0), ":t"), pattern_list)
  end,
}

M.sign_handlers = {}
-- gitsigns handlers
local gitsigns = function(_)
  local gitsigns_avail, gitsigns = pcall(require, "gitsigns")
  if gitsigns_avail then vim.schedule(gitsigns.preview_hunk) end
end
for _, sign in ipairs { "Topdelete", "Untracked", "Add", "Changedelete", "Delete" } do
  local name = "GitSigns" .. sign
  if not M.sign_handlers[name] then M.sign_handlers[name] = gitsigns end
end
-- diagnostic handlers
local diagnostics = function(args)
  if args.mods:find "c" then
    vim.schedule(vim.lsp.buf.code_action)
  else
    vim.schedule(vim.diagnostic.open_float)
  end
end
for _, sign in ipairs { "Error", "Hint", "Info", "Warn" } do
  local name = "DiagnosticSign" .. sign
  if not M.sign_handlers[name] then M.sign_handlers[name] = diagnostics end
end
-- DAP handlers
local dap_breakpoint = function(_)
  local dap_avail, dap = pcall(require, "dap")
  if dap_avail then vim.schedule(dap.toggle_breakpoint) end
end
for _, sign in ipairs { "", "Rejected", "Condition" } do
  local name = "DapBreakpoint" .. sign
  if not M.sign_handlers[name] then M.sign_handlers[name] = dap_breakpoint end
end

return M
