return {
  { "nvim-lua/plenary.nvim", lazy = true },
  { "echasnovski/mini.bufremove", lazy = true },
  { "rebelot/kanagawa.nvim", priority = 1000, },
  { "max397574/better-escape.nvim", event = "InsertCharPre", opts = { timeout = 300 } },
  {
    "s1n7ax/nvim-window-picker",
    lazy = true,
    opts = { ignored_filetypes = { "nofile", "quickfix", "qf", "prompt" }, ignored_buftypes = { "nofile" } },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  }
}
