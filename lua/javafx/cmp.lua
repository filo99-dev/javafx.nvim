-- nvim-cmp source, registered as "javafx" (add { name = "javafx" } to your sources).
local complete = require("javafx.complete")
local M = {}

local source = {}
function source.new() return setmetatable({}, { __index = source }) end
function source:is_available() return vim.api.nvim_buf_get_name(0):match("%.fxml$") ~= nil end
function source:get_trigger_characters() return { "<", '"', "." } end
function source:complete(params, callback)
  local before = params.context.cursor_before_line
  callback(complete.items_at(before, params.context.cursor.row - 1, #before, vim.api.nvim_get_current_buf()))
end

function M.register()
  local ok, cmp = pcall(require, "cmp")
  if ok then cmp.register_source("javafx", source.new()) end
end

return M
