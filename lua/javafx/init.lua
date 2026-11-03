local M = {}

M.config = {
  -- Path to the Scene Builder executable. nil = auto-detect.
  scene_builder = nil,
  -- How the run terminal is opened.
  run_split = "botright 15split",
  -- Maven goal (needs org.openjfx:javafx-maven-plugin) and Gradle task.
  maven_goal = "javafx:run",
  gradle_task = "run",
  -- Where controllers / FXML live, relative to the project root.
  source_roots = { "src/main/java" },
  resource_roots = { "src/main/resources" },
  -- fx:controller completion: only suggest classes whose name ends with the suffix.
  -- Set controllers_only = false to suggest every class (controllers still sorted first).
  controllers_only = true,
  controller_suffix = "Controller",
  -- Save all buffers before :JavaFXRun.
  save_before_run = true,
  -- Set to true to get default <leader>j* mappings.
  mappings = false,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  if M.config.mappings then
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = "JavaFX: " .. desc })
    end
    map("<leader>jr", "<cmd>JavaFXRun<cr>", "run")
    map("<leader>jx", "<cmd>JavaFXStop<cr>", "stop")
    map("<leader>jt", "<cmd>JavaFXToggle<cr>", "toggle FXML/controller")
    map("<leader>ji", "<cmd>JavaFXInject<cr>", "inject fields/handlers")
    map("<leader>js", "<cmd>JavaFXSceneBuilder<cr>", "Scene Builder")
  end
end

return M
