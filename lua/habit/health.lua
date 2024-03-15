local M = {}

-- TODO remove deprecated method check after dropping support for 0.9
local health = {
  start = vim.health.start or vim.health.report_start,
  ok = vim.health.ok or vim.health.report_ok,
  warn = vim.health.warn or vim.health.report_warn,
  error = vim.health.error or vim.health.report_error,
  info = vim.health.info or vim.health.report_info,
}

function M.check()
  health.start "Habit"

  health.info("nvim version: v" .. vim.fn.matchstr(vim.fn.execute "version", "NVIM v\\zs[^\n]*"))

  if vim.version().prerelease then
    health.warn "neovim nightly is not officially supported & may have breaking changes"
  elseif vim.fn.has "nvim-0.8" == 1 then
    health.ok "using stable nvim >= 0.8.0"
  else
    health.error "nvim >= 0.8.0 required"
  end

  local programs = {
    {
      cmd = { "git" },
      type = "error",
      msg = "used for core functionality such as plugin mgmt",
      extra_check = function(program)
        local git_version = require("habit.utils.git").git_version()
        if git_version then
          if git_version.major < 2 or (git_version.major == 2 and git_version.min < 19) then
            program.msg = ("git %s installed, >= 2.19.0 is required"):format(git_version.str)
          else
            return true
          end
        else
          program.msg = "unable to validate git version"
        end
      end,
    },
    {
      cmd = { "xdg-open", "open" },
      type = "warn",
      msg = "used for `gx` mapping for opening files with system opener (optional)",
    },
    { cmd = { "lazygit" }, type = "warn", msg = "used for mappings to pull up git tui (optional)" },
    { cmd = { "node" }, type = "warn", msg = "used for mappings to pull up node repl (optional)" },
    {
      cmd = { vim.fn.has "mac" == 1 and "gdu-go" or "gdu" },
      type = "warn",
      msg = "used for mappings to pull up disk usage analyzer (optional)",
    },
    { cmd = { "btm" }, type = "warn", msg = "used for mappings to pull up a system monitor (optional)"},
    { cmd = { "python", "python3" }, type = "warn", msg = "used for mappings to pull up python repl (optional)" },
  }

  for _, program in ipairs(programs) do
    local name = table.concat(program.cmd, "/")
    local found = false
    for _, cmd in ipairs(program.cmd) do
      if vim.fn.executable(cmd) == 1 then
        name = cmd
        if not program.extra_check or program.extra_check(program) then found = true end
        break
      end
    end

    if found then
      health.ok(("`%s` is installed: %s"):format(name, program.msg))
    else
      health[program.type](("`%s` is not installed: %s"):format(name, program.msg))
    end
  end
end

return M
