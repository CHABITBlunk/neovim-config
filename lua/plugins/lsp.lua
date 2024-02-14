return {
  { "b0o/SchemaStore.nvim", lazy = true },
  {
    "folke/neodev.nvim",
    lazy = true,
    opts = {
      override = function(root_dir, library)
        if root_dir:match(vim.fn.stdpath "config") then
          library.plugins = true
        end
      vim.b.neodev_enabled = library.enabled
      end,
    },
  },
  { "neovim/nvim-lspconfig" },
  {
    "williamboman/mason-lspconfig.nvim",
    cmd = { "LspInstall", "LspUninstall" },
    opts = function(_, opts)
      if not opts.handlers then opts.handlers = {} end
      opts.handlers[1] = function(server) require("habit.utils.lsp").setup(server) end
    end,
    config = require "plugins.configs.mason-lspconfig"
  }
}
