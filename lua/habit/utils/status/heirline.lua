--- status heirline extensions
--
-- load with `local heirline = require "habit.utils.status.heirline"`

local M = {}

local hl = require "habit.utils.status.hl"
local provider = require "habit.utils.status.provider"
local status_utils = require "habit.utils.status.utils"

local utils = require "habit.utils"
local buffer_utils = require "habit.utils.buffer"
local get_icon = utils.get_icon

--- get type of tab/buffer
---@param self table the self table from a heirline component function
---@param prefix? string the prefix of the type, either "tab" or "buffer" (default: "buffer")
---@return string # the string of prefix with type (i.e. "_active" or "_visible")
function M.tab_type(self, prefix)
  local tab_type = ""
  if self.is_active then
    tab_type = "_active"
  elseif self.is_visible then
    tab_type = "_visible"
  end
  return (prefix or "buffer") .. tab_type
end

--- make a list of buffers, rendering each buffer w provided component
---@param component table the self table from a heirline component function
---@return table
function M.make_buflist(component)
  local overflow_hl = hl.get_attributes("buffer_overflow", true)
  return require("heirline.utils").make_buflist(
    status_utils.surround(
      "tab",
      function (self)
        return {
          main = M.tab_type(self) .. "_bg",
          left = "tabline_bg",
          right = "tabline_bg",
        }
      end,
      { -- bufferlist
        init = function(self) self.tab_type = M.tab_type(self) end,
        { -- add buffer picker functionality to each buffer
          condition = function(self) return self._show_picker end,
          update = false,
          init = function (self)
            if not (self.label and self._picker_labels[self.label]) then
              local bufname = provider.filename()(self)
              local label = bufnmae:sub(1, 1)
              local i = 2
              while label ~= " " and self._picker_labels[label] do
                if i > #bufname then break end
                label = bufname:sub(i, i)
                i = i + 1
              end
              self._picker_labels[label] = self.bufnr
              self.label = label
            end
          end,
          provider = function(self) return provider.str { str = self.lable, padding = { left = 1, right = 1 } } end,
          hl = hl.get_attributes "buffer_picker",
        },
        component, -- create buffer component
      },
      function(self) return buffer_utils.is_valid(self.bufnr) end -- disable surrounding
    ),
    { provider = get_icon "ArrowLeft" .. " ", hl = overflow_hl },
    { provider = get_icon "ArrowRight" .. " ", hl = overflow_hl },
    function() return vim.t.bufs or {} end, -- use astronvim bufs variable
    false -- disable internal caching
  )
end

--- alias to require("heirline.utils").make_tablist
function M.make_tablist(...) return require("heirline.utils").make_tablist(...) end

--- run buffer picker and execute callback function on selected buffer
---@param callback function with a single parameter of bufnr
function M.buffer_picker(callback)
  local tabline = require("heirline").tabline
  -- if buflist then
  local prev_showtabline = vim.opt.showtabline:get()
  if prev_showtabline ~= 2 then vim.opt.showtabline = 2 end
  vim.cmd.redrawtabline()
  ---@diagnostic disable-next-line: undefined-field
  local buflist = tabline and tabline._buflist and tabline._buflist[1]
  if buflist then
    buflist._picker_labels = {}
    buflist._show_picker = true
    vim.cmd.redrawtabline()
    local char = vim.fn.getcharstr()
    local bufnr = buflist._picker_labels[char]
    if bufnr then callback(bufnr) end
    buflist._show_picker = false
  end
  if prev_showtabline ~= 2 then vim.opt.showtabline = prev_showtabline end
  vim.cmd.redrawtabline()
  -- end
end

return M
