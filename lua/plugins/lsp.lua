return {
  { "b0o/SchemaStore.nvim", lazy = true },
  {
    "folke/neodev.nvim",
    lazy = true,
    opts = {
      override = function(root_dir, library)
        if root_dir:match(vim.fn.stdpath "config") then library.plugins = true end
        vim.b.neodev_enabled = library.enabled
      end,
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "folke/neoconf.nvim" },
      {
        "williamboman/mason-lspconfig.nvim",
        cmd = { "LspInstall", "LspUninstall" },
        opts = function(_, opts)
          if not opts.handlers then opts.handlers = {} end
          opts.handlers[1] = function(server) require("habit.utils.lsp").setup(server) end
        end,
        config = require "plugins.configs.mason-lspconfig"
      },
    },
    cmd = function(_, cmds) -- HACK: lazy load lspconfig on `:Neoconf` if neoconf is available
      if require("habit.utils").is_available "neoconf.nvim" then table.insert(cmds, "Neoconf") end
    end,
    event = "User File",
    config = require "plugins.configs.lspconfig",
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "jay-babu/mason-null-ls.nvim",
      cmd = { "NullLsInstall", "NullLsUninstall" },
      opts = { handlers = {} },
    },
    event = "User File",
    opts = function() return { on_attach = require("habit.utils.lsp").on_attach } end,
  },
  {
    "stevearc/aerial.nvim",
    event = "User File",
    opts = {
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      disable_max_lines = false,
      disable_max_size = false,
      layout = { min_width = 28 },
      show_guides = true,
      filter_kind = false,
      guides = {
        mid_item = "├ ",
        last_item = "└ ",
        nested_top = "│ ",
        whitespace = "  ",
      },
      keymaps = {
        ["[y"] = "actions.prev",
        ["]y"] = "actions.next",
        ["[Y"] = "actions.prev_up",
        ["]Y"] = "actions.next_up",
        ["{"] = false,
        ["}"] = false,
        ["[["] = false,
        ["]]"] = false,
      },
    },
  },
}
