-- vim options
local o = vim.o
local g = vim.g

o.breakindent = true
if not vim.env.SSH_TTY or vim.fn.has("nvim-0.10") ~= 1 then
	o.clipboard = "unnamedplus"
end
o.cmdheight = 0
o.copyindent = true
o.cursorline = true
o.expandtab = true
o.fillchars = { eob = " " }
o.foldcolumn = "1"
o.foldenable = true
o.foldlevel = 99
o.foldlevelstart = 99
o.ignorecase = false
o.infercase = false
o.laststatus = 3
o.linebreak = true
o.mouse = ""
o.number = true
o.preserveindent = true
o.pumheight = 10
o.relativenumber = true
o.shiftround = true
o.shiftwidth = 0
o.showmode = false
o.showtabline = 2
o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.tabstop = 2
o.termguicolors = true
o.timeoutlen = 500
o.title = true
o.undofile = true
o.updatetime = 250
o.virtualedit = "block"
o.wrap = false
o.writebackup = false

g.mapleader = " "
