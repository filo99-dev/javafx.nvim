local M = {}

function M.register()
  local cmd = vim.api.nvim_create_user_command

  cmd("JavaFXRun", function() require("javafx.run").run() end,
    { desc = "Run the JavaFX app (Maven/Gradle)" })
  cmd("JavaFXStop", function() require("javafx.run").stop() end,
    { desc = "Stop the running JavaFX app" })
  cmd("JavaFXToggle", function() require("javafx.controller").toggle() end,
    { desc = "Jump between FXML and its controller" })
  cmd("JavaFXInject", function() require("javafx.controller").inject() end,
    { desc = "Add @FXML fields/handlers to the controller" })
  cmd("JavaFXNew", function(o) require("javafx.new").create(o.fargs[1], o.fargs[2]) end,
    { nargs = "*", desc = "Create FXML + controller" })
  cmd("JavaFXSceneBuilder", function(o)
    require("javafx.scenebuilder").open(o.args ~= "" and o.args or nil)
  end, { nargs = "?", complete = "file", desc = "Open FXML in Scene Builder" })
end

return M
