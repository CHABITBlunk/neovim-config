local M = {}

local utils = require "habit.utils"

M.current_buf, M.last_buf = nil, nil

--- close a given tab
---@param tabpage? integer the tabpage to close or the current tab if not provided
function M.close_tab(tabpage)
  if #vim.api.nvim_list_tabpages() > 1 then
    tabpage = tabpage or vim.api.nvim_get_current_tabpage()
    vim.t[tabpage].bufs = nil
    utils.event "BufsUpdated"
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tabpage))
  end
end

--- check if buffer is valid
---@param bufnr number? the number to check, default to current buffer
---@return boolean whether buffer is valid or not
function M.is_valid(bufnr)
  if not bufnr then bufnr = 0 end
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end
