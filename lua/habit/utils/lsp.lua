--- lsp related util functions
-- 
-- load with `local lsp_utils = require("habit.utils.lsp")`

local M = {}
local tbl_contains = vim.tbl_contains
local tbl_isempty = vim.tbl_isempty

local utils = require "habit.utils"
local conditional_func = utils.conditional_func
local is_available = utils.is_available
local extend_tbl = utils.extend_tbl

local server_config = "lsp.config."
local setup_handlers = {
  function(server, opts) require("lspconfig")[server].setup(opts) end,
}

M.diagnostics = { [0] = {}, {}, {}, {} }

M.setup_diagnostics = function(signs)
  local default_diagnostics = {
    virtual_text = true,
    signs = {
      text = {
        [vim.diagnostic.severity.E] = utils.get_icon "DiagnosticError",
        [vim.diagnostic.severity.H] = utils.get_icon "DiagnosticHint",
        [vim.diagnostic.severity.W] = utils.get_icon "DiagnosticWarn",
        [vim.diagnostic.severity.I] = utils.get_icon "DiagnosticInfo",
      },
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focused = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }
  M.diagnostics = {
    -- diagnostics off
    [0] = extend_tbl(
      default_diagnostics,
      { underline = false, virtual_text = false, signs = false, update_in_insert = false }
    ),
    -- status only
    extend_tbl(default_diagnostics, { virtual_text = false, signs = false }),
    -- virtual text off, signs on
    extend_tbl(default_diagnostics, { virtual_text = false }),
    -- all diagnostics on
    default_diagnostics,
  }

  vim.diagnostic.config(M.diagnostics[vim.g.diagnostics_mode])
end

M.formatting = { format_on_save = { enabled = true }, disabled = {} }
if type(M.formatting.format_on_save) == "boolean" then
  M.formatting.format_on_save = { enabled = M.formatting.format_on_save }
end

M.format_opts = vim.deepcopy(M.formatting)
M.format_opts.disabled = nil
M.format_opts.format_on_save = nil
M.format_opts.filter = function(client)
  local filter = M.formatting.filter
  local disabled = M.formatting.disabled or {}
  -- check if client is fully disabled or filtered by function
  return not (tbl_contains(disabled, client.name) or (type(filter) == "function" and not filter(client)))
end

--- helper funciton to set up a given server within neovim lsp client
---@param server string the name of the server to be set up
M.setup = function(server)
  -- if server doesn't exist, set it up from user server definition
  local config_avail, config = pcall(require, "lspconfig.server_configurations." .. server)
  if not config_avail or not config.default_config then
    local server_definition = server_config .. server
    if server_definition.cmd then require("lspconfig.configs")[server] = { default_config = server_definition } end
  end
  local opts = M.config(server)
  local setup_handler = setup_handlers[server] or setup_handlers[1]
  if setup_handler then setup_handler(server, opts) end
end

--- helper function to check if any active lsp clients given a filter provide a specific capability
---@param capability string the server capability to check for
---@param filter vim.lsp.get_active_clients.filter|nil (table|nil) a table with
--               key-value pairs used to filter the returned clients.
--               available keys are:
--               - id (number): only return clients w given id
--               - bufnr (number): only return clients attached to this buffer
--               - name (string): only return clients with given name
---@return boolean # whether or not any client provides capability
function M.has_capability(capability, filter)
  for _, client in ipairs(vim.lsp.get_active_clients(filter)) do
    if client.supports_method(capability) then return true end
  end
  return false
end

local function add_buffer_autocmd(augroup, bufnr, autocmds)
  if not vim.tbl_islist(autocmds) then autocmds = { autocmds } end
  local cmds_found, cmds = pcall(vim.api.nvim_get_autocmds, { group = augroup, buffer = bufnr })
  if not cmds_found or tbl_isempty(cmds) then
    vim.api.nvim_create_augroup(augroup, { clear = false })
    for _, autocmd in ipairs(autocmds) do
      local events = autocmd.events
      autocmd.events = nil
      autocmd.group = augroup
      autocmd.buffer = bufnr
      vim.api.nvim_create_autocmd(events, autocmd)
    end
  end
end

local function del_buffer_autocmd(augroup, bufnr)
  local cmds_found, cmds = pcall(vim.api.nvim_get_autocmds, { group = augroup, buffer = bufnr })
  if cmds_found then vim.tbl_map(function(cmd) vim.api.nvim_del_autocmd(cmd.id) end, cmds) end
end

--- on_attach (heavily borrowed from astronvim)
---@param client table the lsp client details when attaching
---@param bufnr number the buffer that the lsp client is attaching to
M.on_attach = function(client, bufnr)
  local lsp_mappings = require("habit.utils").empty_map_table()

  lsp_mappings.n["<leader>ld"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
  lsp_mappings.n["[d]"] = { function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostics" }
  lsp_mappings.n["]d"] = { function() vim.diagnostic.goto_next() end, desc = "Next diagnostics" }
  lsp_mappings.n["gl"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }

  if is_available "telescope.nvim" then
    lsp_mappings.n["<leader>lD"] = 
      { function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" }
  end

  if is_available "mason-lspconfig.nvim" then
    lsp_mappings.n["<leader>li"] = { "<cmd>LspInfo<cr>", desc = "LSP Information" }
  end

  if is_available "null-ls.nvim" then
    lsp_mappings.n["<leader>lI"] = { "<cmd>NullLsInfo<cr>", desc = "Null-ls information" }
  end

  if client.supports_method "textDocument/codeAction" then
    lsp_mappings.n["<leader>la"] = {
      function() vim.lsp.buf.code_action() end,
      desc = "LSP code action",
    }
    lsp_mappings.v["<leader>la"] = lsp_mappings.n["<leader>la"]
  end

  if client.supports_method "textDocument/codeLens" then
    add_buffer_autocmd("lsp_codelens_refresh", bufnr, {
      events = { "InsertLeave", "BufEnter" },
      desc = "Refresh codelens",
      callback = function()
        if not M.has_capability("textDocument/codeLens", { bufnr = bufnr }) then
          del_buffer_autocmd("lsp_codelens_refresh", bufnr)
          return
        end
        vim.lsp.codelens.refresh()
      end,
    })
    vim.lsp.codelens.refresh()
    lsp_mappings.n["<leader>ll"] = {
      function() vim.lsp.codelens.refresh() end,
      desc = "LSP CodeLens refresh",
    }
    lsp.mappings.n["<leader>lL"] = {
      function() vim.lsp.codelens.run() end,
      desc = "LSP CodeLens run",
    }
  end

  if client.supports_method "textDocument/definition" then
    lsp_mappings.n["gd"] = {
      function() vim.lsp.buf.definition() end,
      desc = "Show definition of current symbol",
    }
  end

  if client.supports_method "textDocument/formatting" and not tbl_contains(M.formatting.disabled, client.name) then
    lsp_mappings.n["<leader>lf"] = {
    function() vim.lsp.buf.format(M.format_opts) end,
    desc = "Format buffer",
    }
    lsp_mappings.v["<leader>lf"] = lsp_mappings.n["<leader>lf"]

    vim.api.nvim_buf_create_user_command(
      bufnr,
      "Format",
      function() vim.lsp.buf.format(M.format_opts) end,
      { desc = "Format file with LSP" }
    )
    local autoformat = M.formatting.format_on_save
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    if
      autoformat.enabled
      and (tbl_isempty(autoformat.allow_filetypes or {}) or tbl_contains(autoformat.allow_filetypes, filetype))
      and (tbl_isempty(autoformat.allow_filetypes or {}) or not tbl_contains(autoformat.ignore_filetypes, filetype))
    then
      add_buffer_autocmd("lsp_auto_format", bufnr, {
        events = "BufWritePre",
        desc = "autoformat on save",
        callback = function()
          if not M.has_capability("textDocument/formatting", { bufnr = bufnr }) then
            del_buffer_autocmd("lsp_auto_format", bufnr)
            return
          end
          local autoformat_enabled = true
          if autoformat_enabled and ((not autoformat.filter) or autoformat.filter(bufnr)) then
            vim.lsp.buf.format(extend_tbl(M.format_opts, { bufnr = bufnr }))
          end
        end,
      })
    end
  end

  if client.supports_method "textDocument/documentHighlight" then
    add_buffer_autocmd("lsp_document_highlight", bufnr, {
      {
        events = { "CursorHold", "CursorHoldI" },
        desc = "highlight references when cursor holds",
        callback = function()
          if not M.has_capability("textDocument/documentHighlight", { bufnr = bufnr }) then
            del_buffer_autocmd("lsp_document_highlight", bufnr)
            return
          end
          vim.lsp.buf.document_highlight()
        end
      },
      {
        events = { "CursorMoved", "CursorMovedI", "BufLeave" },
        desc = "clear references when cursor moves",
        callback = function() vim.lsp.buf.clear_references() end,
      },
    })
  end

  if client.supports_method "textDocument/hover" then
    -- TODO remove after getting neovim 0.10; this is automatically done
    if vim.fn.has "nvim-0.10" then
      lsp_mappings.n["K"] = {
        function() vim.lsp.buf.hover() end,
        desc = "Hover symbol details",
      }
    end
  end

  if client.supports_method "textDocument/implementation" then
    lsp_mappings.n["gI"] = {
      function() vim.lsp.buf.implementation() end,
      desc = "Implementation of current symbol",
    }
  end

  if client.supports_method "textDocument/inlayHint" then
    if vim.b.inlay_hints_enabled == nil then vim.b.inlay_hints_enabled = true end
    -- TODO remove check after switching to neovim v0.10
    if vim.lsp.inlay_hint then
      if vim.b.inlay_hints_enabled then vim.lsp.inlay_hint.enable(bufnr, true) end
    end
  end
end

return M

