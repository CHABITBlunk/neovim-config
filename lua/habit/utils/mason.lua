--- mason utils
--
-- mason related utility functions
--
-- load with `local mason_utils = require "habit.utils.mason"`

local M = {}

local utils = require "habit.utils"
local event = utils.event

--- update specified mason packages, or just update registries if no packages listed
---@param pkg_names? string|string[] the package names as defined in mason
---@param auto_install? boolean whether or not not to install a package not currently installed
function M.update(pkg_names, auto_install)
  pkg_names = pkg_names or {}
  if type(pkg_names) == "string" then pkg_names = { pkg_names } end
  if auto_install == nil then auto_install = true end
  local registry_avail, registry = pcall(require, "mason-registry")
  if not registry_avail then
    vim.api.nvim_err_writeln "unable to access mason registry"
    return
  end

  registry.update(vim.schedule_wrap(function(success, updated_registries)
    if success then
      for _, pkg_name in ipairs(pkg_names) do
        local pkg_avail, pkg = pcall(registry.get_package, pkg_name)
        if not pkg_avail then
          utils.notify(("`%s` not available"):format((pkg_name), vim.log.levels.ERROR))
        else
          if not pkg:is_installed() then
            if auto_install then
              pkg:install()
            else
              utils.notify(("`%s` not installed"):format(pkg.name), vim.log.levels.WARN)
            end
          else
            pkg:check_new_version(function(update_available)
              if update_available then
                pkg:install()
              end
            end)
          end
        end
      end
    else
      utils.notify(("Failed to update registries: %s"):format(updated_registries), vim.log.levels.ERROR)
    end
  end))
end

--- update all packages in mason
function M.update_all()
  local registry_avail, registry = pcall(require, "mason-registry")
  if not registry_avail then
    vim.api.nvim_err_writeln "Unable to access mason registry"
  end

  registry.update(vim.schedule_wrap(function (success, updated_registries)
    if success then
      local installed_pkgs = registry.get_installed_packages()
      local running = #installed_pkgs
      local no_pkgs = running == 0

      if no_pkgs then
        event "MasonUpdateCompleted"
      else
        for _, pkg in ipairs(installed_pkgs) do
          pkg:check_new_version(function(update_available)
            if update_available then
              pkg:install():on("closed", function() running = running - 1
                if running == 0 then
                  event "MasonUpdateCompleted"
                end
              end)
            else
              running = running - 1
              if running == 0 then
                event "MasonUpdateCompleted"
              end
            end
          end)
        end
      end
    else
      utils.notify(("Failed to update registries: %s"):format(updated_registries), vim.log.levels.ERROR)
    end
  end))
end

return M
