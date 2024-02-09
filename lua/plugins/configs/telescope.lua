return function(_, opts)
  local telescope = require "telescope"
  telescope.setup(opts)
  local utils = require "habit.utils"
  local conditional_func = utils.conditional_func
  conditional_func(telescope.load_extension, pcall(require, "aerial"), "aerial")
  conditional_func(telescope.load_extension, pcall(require, "telescope-fzf-native.nvim"), "fzf")
end
