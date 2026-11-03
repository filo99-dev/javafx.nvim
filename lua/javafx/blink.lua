-- blink.cmp source: module = "javafx.blink"
local complete = require("javafx.complete")

local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source:enabled()
  return vim.api.nvim_buf_get_name(0):match("%.fxml$") ~= nil
end

function Source:get_trigger_characters()
  return { "<", '"', "." }
end

function Source:get_completions(ctx, callback)
  local row, col = ctx.cursor[1] - 1, ctx.cursor[2]
  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = complete.items_at(ctx.line:sub(1, col), row, col, vim.api.nvim_get_current_buf()),
  })
  return function() end
end

return Source
