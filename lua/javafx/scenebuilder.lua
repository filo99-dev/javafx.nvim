local util = require("javafx.util")
local M = {}

function M.open(file)
  local cfg = require("javafx").config
  file = file or vim.api.nvim_buf_get_name(0)
  if not file:match("%.fxml$") then
    return util.notify("Not an .fxml file", vim.log.levels.WARN)
  end
  file = vim.fn.fnamemodify(file, ":p")

  local cmd
  if cfg.scene_builder then
    cmd = { cfg.scene_builder, file }
  elseif vim.fn.has("mac") == 1 then
    cmd = { "open", "-a", "Scene Builder", file }
  elseif vim.fn.executable("scenebuilder") == 1 then
    cmd = { "scenebuilder", file }
  elseif vim.fn.executable("SceneBuilder") == 1 then
    cmd = { "SceneBuilder", file }
  else
    return util.notify("Scene Builder not found; set `scene_builder` in setup()", vim.log.levels.ERROR)
  end
  vim.fn.jobstart(cmd, { detach = true })
end

return M
