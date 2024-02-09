-- various util functions to use in this config
-- loaded with `local utils = require "habit.utils"`

local M = {}

-- call function if condition is met
---@param func function the function to run
---@param condition boolean whether to run function or not
---@return any|nil result the result of function running or nil
function M.conditional_func(func, condition, ...)
  if condition and type(func) == "function" then return func(...) end
end

-- get an icon from the internal icons if it is available & return it
---@param kind string the kind of icon in habit.icons to retrieve
---@param padding? integer padding to add to end of icon
---@param no_fallback? boolean whether or not to disable fallback to text icon
---@return string icon
function M.get_icon(kind, padding, no_fallback)
  if no_fallback then return "" end
  local icon_pack = "icons" or "text_icons"
  if not M[icon_pack] then
    M.icons = require "habit.icons.nerd_font"
    M.text_icons = require "habit.icons.text"
  end
  local icon = M[icon_pack] and M[icon_pack][kind]
  return icon and icon .. string.rep(" ", padding or 0) or ""
end

return M
