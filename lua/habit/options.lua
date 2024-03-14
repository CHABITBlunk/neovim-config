vim.opt.viewoptions:remove "curdir" -- disable saving current directory with views
vim.opt.shortmess:append { s = true, I = true } -- disable search count wrap & startup messages
vim.opt.backspace:append { "nostop" } -- don't stop backspace at insert
if vim.fn.has "nvim-0.9" then
  vim.opt.diffopt:append "linematch:60" -- enable linematch diff algorithm
end

local options = {
  o = {
    breakindent = true, -- wrap indent to match line start
    clipboard = "unnamedplus", -- connection to system clipboard
    cmdheight = 0, -- hide command line unless needed
    completeopt = { "menu", "menuone", "noselect" }, -- options for insert mode completion
    copyindent = true, -- copy previous indentation on autoindenting
    cursorline = true, -- highlight text line of cursor
    expandtab = true, -- enable use of space in tab
    fileencoding = "utf-8", -- file content encoding for buffer
    fillchars = { eob = " " }, -- disable '~' on nonexistent lines
    history = 100, -- number of commands to remember in history table
    ignorecase = true, -- case insensitive searching
    infercase = true, -- infer cases in keyword completion
    laststatus = 3, -- global statusline
    linebreak = true, -- wrap lines at "breakat"
    mouse = "", -- disable mouse
    number = true, -- show numberline
    preserveindent = true, -- preserve indent structure as much as possible
    pumheight = 10, -- height of pop up menu
    relativenumber = true, -- show relative numberline
    shiftwidth = 2, -- number of space inserted for indentation
    showmode = false, -- disable showing modes in command line
    showtabline = 2, -- always display tabline
    signcolumn = "yes", -- always show sign column
    smartcase = true, -- case sensitive searching
    splitbelow = true, -- splits horizontally below current window
    splitright = true, -- splits vertically to right of current window
    tabstop = 2, -- number of space in a tab
    termguicolors = true, -- enable 24-bit rgb in tui
    timeoutlen = 500, -- shorten key timeout a little for which-key
    title = true, -- set terminal title to filename & path
    undofile = true, -- enable persistent undo
    updatetime = 300, -- length of time to wait before triggering plugin
    virtualedit = "block", -- allow going past end of line in visual block mode
    wrap = false, -- disable wrapping of lines longer than width of window
    writebackup = false, -- disable making a backup before overwriting a file
  },
  g = {
    mapleader = " ", -- set leader key
    -- my specific global options
    max_file = { size = 1024 * 100, lines = 10000 }, -- set global limits for large files
    autoformat_enabled = true, -- enable auto formatting at start (lsp.formatting.format_on_save must be enabled)
    autopairs_enabled = true, -- enable autopairs at start
    cmp_enabled = true, -- enable completion at start
    codelens_enabled = true, -- enable automatic codelens refreshing for lsp that support it
    diagnostics_mode = 3, -- set visibility of diagnostics in ui (0=off, 1=only show in status line, 2=virtual text off, 3=all on)
    highlighturl_enabled = true,
    inlay_hints_enabled = false, -- enable lsp inlay hints on startup (v0.10 only)
    lsp_handlers_enabled = true, -- enable default vim.lsp.handlers (hover & signature help)
    semantic_tokens_enabled = true, -- enable lsp semantic tokens on startup
    git_worktrees = nil,
  },
  t = vim.t.bufs and vim.t.bufs or { bufs = vim.api.nvim_list_bufs() }, -- initialize buffers for current tab
}

for scope, table in pairs(options) do
  for setting, value in pairs(table) do
    vim[scope][setting] = value
  end
end
