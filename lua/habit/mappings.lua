local utils = require "habit.utils"
local get_icon = utils.get_icon
local is_available = utils.is_available
local ui = require "habit.utils.ui"

local maps = require("habit.utils").empty_map_table()

local sections = {
  f = { desc = get_icon("Search", 1, true) .. "Find" },
  p = { desc = get_icon("Package", 1, true) .. "Packages" },
  l = { desc = get_icon("ActiveLSP", 1, true) .. "LSP" },
  u = { desc = get_icon("Window", 1, true) .. "UI/UX" },
  b = { desc = get_icon("Tab", 1, true) .. "Buffers" },
  bs = { desc = get_icon("Sort", 1, true) .. "Sort Buffers" },
  d = { desc = get_icon("Debugger", 1, true) .. "Debugger" },
  g = { desc = get_icon("Git", 1, true) .. "Git" },
  S = { desc = get_icon("Session", 1, true) .. "Session" },
  t = { desc = get_icon("Terminal", 1, true) .. "Terminal" },
}

-- neotree
if is_available "neo-tree.nvim" then
  maps.n["<leader>e"] = {"<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
  maps.n["<leader>o"] = {
    function ()
      if vim.bo.filetype == "neo-tree" then
        vim.cmd.wincmd "p"
      else
        vim.cmd.Neotree "focus"
      end
    end,
    desc = "Toggle Explorer Focus",
  }
end

-- telescope
if is_available "telescope.nvim" then
  maps.n["<leader>f"] = sections.f
  maps.n["<leader>g"] = sections.g
  maps.n["<leader>gb"] =
    { function() require("telescope.builtin").git_branches {use_file_path = true } end, desc = "Git branches" }
  maps.n["<leader>gc"] = {
    function() require("telescope.builtin").git_commits { use_file_path = true } end,
    desc = "Git commits (repository)",
  }
  maps.n["<leader>gC"] = {
    function() require("telescope.builtin").git_commits { use_file_path = true } end,
    desc = "Git commits (repository)",
  }
  maps.n["<leader>gt"] =
    { function() require("telescope.builtin").current_buffer_fuzzy_find() end, desc = "Find words in current buffer" }
  maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Find buffers" }
  maps.n["<leader>fc"] = { function() require("telescope.builtin").grep_string() end, desc = "Find word under cursor" }
  maps.n["<leader>fC"] = { function() require("telescope.builtin").commands() end, desc = "Find commands" }
  maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "Find files" }
  maps.n["<leader>fF"] = {
    function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end,
    desc = "Find all files",
  }
  maps.n["<leader>fh"] = { function() require("telescope.builtin").help_tags() end, desc = "Find help" }
  maps.n["<leader>fk"] = { function() require("telescope.builtin").keymaps() end, desc = "Find keymaps" }
  maps.n["<leader>fm"] = { function() require("telescope.builtin").man_pages() end, desc = "Find man" }
  if is_available "nvim-notify" then
    maps.n["<leader>fn"] =
      { function() require("telescope").extensions.notify.notify() end, desc = "Find notifications" }
    maps.n["<leader>uD"] =
      { function() require("notify").dismiss { pending = true, silent = true } end, desc = "Dismiss notifications" }
  end
  maps.n["<leader>fo"] = { function() require("telescope.builtin").oldfiles() end, desc = "Find history" }
  maps.n["<leader>fr"] = { function() require("telescope.builtin").registers() end, desc = "Find registers" }
  maps.n["<leader>ft"] =
    { function() require("telescope.builtin").colorscheme { enable_preview = true } end, desc = "Find themes" }
  maps.n["<leader>fw"] = { function() require("telescope.builtin").live_grep() end, desc = "Find words" }
  maps.n["<leader>fW"] = {
    function()
      require("telescope.builtin").live_grep {
        additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
      }
    end,
    desc = "Find words in all files",
  }
end
