return function(_, opts)
  require("mason-lspconfig").setup(opts)
  require("habit.utils").event "MasonLspSetup"
end
