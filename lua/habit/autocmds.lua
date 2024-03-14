local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local cmd = vim.api.nvim_create_user_command
local namespace = vim.api.nvim_create_namespace

local utils = require "habit.utils"
local is_available = utils.is_available
local event = utils.event

vim.on_key(function(char)
  if vim.fn.mode() == "n" then
    local new_hlsearch = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
    if vim.opt.hlsearch:get() ~= new_hlsearch then vim.opt.hlsearch = new_hlsearch end
  end
end, namespace "auto_hlsearch")

autocmd("BufReadPre", {
  desc = "Disable certain functionality on very large files",
  group = augroup("large_buf", { clear = true }),
  callback = function(args)
    local ok, stats = pcall(vim.loop.fs_fstat, vim.api.nvim_buf_get_name(args.buf))
    vim.b[args.buf].large_buf = (ok and stats and stats.size > vim.g.max_file.size)
  end,
})

autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  desc = "check if buffers changed on editor focus",
  group = augroup("checktime", { clear = true }),
  command = "checktime",
})

autocmd("BufWritePre", {
  desc = "Automatically create parent dirs if they don't exist when saving a file",
  group = augroup("create_dir", { clear = true }),
  callback = function(args)
    if not require("habit.utils.buffer").is_valid(args.buf) then return end
    vim.fn.mkdir(vim.fn.fnamemodify(vim.loop.fs_realpath(args.match) or args.match, ":p:h"), "p")
  end,
})

local terminal_settings_group = augroup("terminal_settings", { clear = true })
-- TODO drop when dropping support for 0.9
if vim.fn.has "nvim-0.9" == 1 and vim.fn.has "nvim-0.9.4" == 0 then
  -- HACK: disable custom statuscolumn for terminals because truncation/wrapping bug
  -- https://github.com/neovim/neovim/issues/25472
  autocmd("TermOpen", {
    group = terminal_settings_group,
    desc = "Disable custom statuscolumn for terminals to fix neovim/neovim#25472",
    callback = function() vim.opt_local.statuscolumn = nil end,
  })
end
autocmd("TermOpen", {
  group = terminal_settings_group,
  desc = "Disable foldcolumn & signcolumn for terminals",
  callback = function()
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.signcolumn = "no"
  end,
})

local bufferline_group = augroup("bufferline", { clear = true })
autocmd({ "BufAdd", "BufEnter", "TabNewEntered" }, {
  desc = "Update buffers when adding new buffers",
  group = bufferline_group,
  callback = function(args)
    local buf_utils = require "habit.utils.buffer"
    if not vim.t.bufs then vim.t.bufs = {} end
    if not buf_utils.is_valid(args.buf) then return end
    if args.buf ~= buf_utils.current_buf then
      buf_utils.last_buf = buf_utils.is_valid(buf_utils.current_buf) and buf_utils.current_buf or nil
      buf_utils.current_buf = args.buf
    end
    local bufs = vim.t.bufs
    if not vim.tbl_contains(bufs, args.buf) then
      table.insert(bufs, args.buf)
      vim.t.bufs = bufs
    end
    vim.t.bufs = vim.tbl_filter(buf_utils.is_valid, vim.t.bufs)
    event "BufsUpdated"
  end,
})
autocmd({ "BufDelete", "TermClose" }, {
  desc = "Update buffers when deleting buffers",
  group = bufferline_group,
  callback = function(args)
    local removed
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local bufs = vim.t[tab].bufs
      if bufs then
        for i, bufnr in ipairs(bufs) do
          if bufnr == args.buf then
            removed = true
            table.remove(bufs, i)
            vim.t[tab].bufs = bufs
            break
          end
        end
      end
    end
    vim.t.bufs = vim.tbl_filter(require("habit.utils.buffer").is_valid, vim.t.bufs)
    if removed then event "BufsUpdated" end
    vim.cmd.redrawtabline()
  end,
})

autocmd({ "VimEnter", "FileType", "BufEnter", "WinEnter" }, {
  desc = "URL Highlighting",
  group = augroup("highlighturl", { clear = true }),
  callback = function() utils.set_url_match() end,
})
