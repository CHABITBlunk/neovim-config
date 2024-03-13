--- core bootstrap
--
-- sets up the global `habit` module
-- autoloaded; should not be resourced. use `habit` variable instead

_G.habit = {}

habit.install = { home = vim.fn.stdpath "config" }
habit.supported_configs = { habit.install.home }
-- "external" config folder
habit.config = vim.fn.stdpath("config"):gsub("[^/]+$", "habit")
if habit.install.home ~= habit.config then
  vim.opt.rtp:append(habit.config)
  -- supported config folders
  table.insert(habit.supported_configs, habit.config)
end

--- looks to see if a module path references a lua file in a config folder & tries to load it. if error loading file, write error & continue
---@param module string the module path to try & load
---@return table|nil out the loaded module if successful or nil
local function load_module_file(module)
  -- placeholder for final return value
  local found_file = nil
  -- search through each supported config locations
  for _, config_path in ipairs(habit.supported_configs) do
    -- convert module path to file path
    local module_path = config_path .. "/lua/" .. module:gsub("%.", "/") .. ".lua"
    -- check if there is a readable file, if so, set it as found
    if vim.fn.filereadable(module_path) == 1 then found_file = module_path end
  end
  -- if we find a readable lua file, try to load it
  local out = nil
  if found_file then
    -- try to load file
    local status_ok, loaded_module = pcall(require, module)
    -- if successful at loading, set return variable
    if status_ok then
      out = loaded_module
    else
      vim.api.nvim_err_writeln("Error writing file: " .. found_file .. "\n\n" .. loaded_module)
    end
  end
  -- return loaded module or nil if no file found
  return out
end

--- main configuration engine logic for extending default config table with either a function override or a table to merge into default opt
---@param overrides table|function the override definition, either a table or a function that takes a single parameter of original table
---@param default table the default config table
---@param extend boolean value to either extend default or simply overwrite it if an override is provided
---@return table default the new config table
local function func_or_extend(overrides, default, extend)
  if extend then
    if type(overrides) == "table" then
      local opts = overrides or {}
      default = default and vim.tbl_deep_extend("force", default, opts) or opts
    elseif type(overrides) == "function" then
      default = overrides(default)
    end
  elseif overrides ~= nil then
    default = overrides
  end
  return default
end

local user_settings = load_module_file "user.init"

--- search settings (user/init.lua table) for table w module like path string
---@param module string the module path like string to look up in the user settings table
---@return any|nil settings the value of the table if it exists or nil
local function user_setting_table(module)
  -- get user settings table
  local settings = user_settings or {}
  -- iterate over path string split by '.' to look up table value
  for tbl in string.gmatch(module, "([^%.]+)") do
    settings = settings[tbl]
    -- if key doesn't exist, keep nil value & stop searching
    if settings == nil then break end
  end
  -- return found settings
  return settings
end

--- user config entry point to override opts of config table w user config file or table in user/init.lua user settings
---@param module string the module path of the (override) setting
---@param default? any the default value that will be overridden
---@param extend? boolean whether to extend the default settings or overwrite them w user settings entirely (default: true)
---@return any # the new config settings with user overrides applied
function habit.user_opts(module, default, extend)
  -- default to extend = true
  if extend == nil then extend = true end
  -- if no default table is provided, set it to empty table
  if default == nil then default = {} end
  -- try to load a module file if it exists
  local user_module_settings = load_module_file("user." .. module)
  if user_module_settings == nil then user_module_settings = user_setting_table(module) end
  -- if a user override was found call config engine
  if user_module_settings ~= nil then default = func_or_extend(user_module_settings, default, extend) end
  -- return final config table w any overrides applied
  return default
end
