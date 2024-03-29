return function(_, _)
  local lsp = require "habit.utils.lsp"
  local utils = require "habit.utils"
  local get_icon = utils.get_icon
  local signs = {
    { name = "DiagnosticSignError", text = get_icon "DiagnosticError", texthl = "DiagnosticSignError" },
    { name = "DiagnosticSignWarn", text = get_icon "DiagnosticWarn", texthl = "DiagnosticSignWarn" },
    { name = "DiagnosticSignHint", text = get_icon "DiagnosticHint", texthl = "DiagnosticSignHint" },
    { name = "DiagnosticSignInfo", text = get_icon "DiagnosticInfo", texthl = "DiagnosticSignInfo" },
    { name = "DapStopped", text = get_icon "DapStopped", texthl = "DiagnosticWarn" },
    { name = "DapBreakpoint", text = get_icon "DapBreakpoint", texthl = "DiagnosticInfo" },
    { name = "DapBreakpointRejected", text = get_icon "DapBreakpointRejected", texthl = "DiagnosticError" },
    { name = "DapBreakpointCondition", text = get_icon "DapBreakpointCondition", texthl = "DiagnosticInfo" },
    { name = "DapLogPoint", text = get_icon "DapLogPoint", texthl = "DiagnosticInfo" },
  }

  for _, sign in pairs(signs) do
    vim.fn.sign_define(sign.name, sign)
  end
  lsp.setup_diagnostics(signs)

  local orig_handler = vim.lsp.handlers["$/progress"]
  vim.lsp.handlers["$/progress"] = function(_, msg, info)
    -- TODO uncomment possibly after creating global "habit" variable, if other solution not found
    -- local progress, id = habit.lsp.progress, ("%s.%s"):format(info.client_id, msg.token)
    -- progress[id] = progress[id] and utils.extend_tbl(progress)
    -- if progress[id].kind == "end" then
      -- progress[id] = nil
      -- utils.event "LspProgress"
    -- end, 100)
    utils.event "LspProgress"
    orig_handler(_, msg, info)
  end

  -- TODO uncomment possibly after creating global "habit" variable, if other solution not found
  -- if vim.g.lsp_handlers_enabled then
    -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded", silent = true })
    -- vim.lsp.handlers["textDocument/signatureHelp"] =
      -- vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded", silent = true })
  -- end
  -- local setup_servers = function()
    -- vim.tbl_map(require("habit.utils.lsp").setup, habit.user_opts "lsp.servers")
    -- vim.api.nvim_exec_autocmds("FileType", { modeline = false })
    -- require("habit.utils").event "LspSetup"
  -- end
  -- if require("habit.utils").is_available "mason-lspconfig.nvim" then
    -- vim.api.nvim_create_autocmd("User", {
      -- desc = "set up LSP servers after mason-lspconfig",
      -- pattern = "MasonLspSetup",
      -- once = true,
      -- callback = setup_servers,
    -- })
  -- else
    -- setup_servers()
  -- end
end
