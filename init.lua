if vim.loader and vim.fn.has "nvim-0.9" == 1 then vim.loader.enable() end

for _, source in ipairs {
  -- "habit.autocmds",
  "habit.lazy",
  "habit.mappings",
  "habit.options",
} do
  local status_ok, fault = pcall(require, source)
  if not status_ok then vim.api.nvim_err_writeln("Failed to load " .. source .. "\n\n" .. fault) end
end
