return {
  -- set colorscheme
  colorscheme = "kanagawa",

  -- diagnostics config (for vim.diagnostics.config({...})) when diagnostics are on
  diagnostics = {
    virtual_text = true,
    underline = true,
  },

  lsp = {
    -- customize lsp formatting opts
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true, -- enable/disable format on save globally
        allow_filetypes = {-- enable format on save for specified filetypes only
          "java",
          "python",
          "lua",
          "c",
          "cpp",
          "markdown",
        },
        ignore_filetypes = {
          -- disable format on save for specified filetypes
        },
      },
      disabled = {
        -- disable formatting capabilities for listed ls
      },
      timeout_ms = 1000, -- default format timeout
    },
    servers = {
      -- enable servers already installed without mason
    },
  },

  -- configure `require("lazy").setup()` opts
  lazy = {
    defaults = { lazy = true },
    performance = {
      rtp = {
        -- customize default disabled vim plugins
        disabled_plugins = { "tohtml", "gzip", "matchit", "zipPlugin", "netrwPlugin", "tarPlugin" },
      },
    },
  },
}
