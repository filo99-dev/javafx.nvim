local util = require("javafx.util")
local M = {}

local CONTROLLER = [[
%spublic class %sController {

    @FXML
    private void initialize() {
    }
}
]]

local FXML = [[
<?xml version="1.0" encoding="UTF-8"?>

<?import javafx.scene.layout.VBox?>

<VBox xmlns="http://javafx.com/javafx/21" xmlns:fx="http://javafx.com/fxml/1"
      fx:controller="%s">
</VBox>
]]

local function current_package()
  if not vim.api.nvim_buf_get_name(0):match("%.java$") then return "" end
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  return text:match("%f[%w]package%s+([%w_.]+)%s*;") or ""
end

local function write(path, content)
  if vim.fn.filereadable(path) == 1 then
    util.notify("Already exists: " .. path, vim.log.levels.ERROR)
    return false
  end
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
  return true
end

local function create(name, pkg)
  local cfg = require("javafx").config
  local root = util.project_root()
  local pkg_path = pkg ~= "" and (pkg:gsub("%.", "/") .. "/") or ""
  local fqcn = (pkg ~= "" and (pkg .. ".") or "") .. name .. "Controller"

  local java_file = ("%s/%s/%s%sController.java"):format(root, cfg.source_roots[1], pkg_path, name)
  local fxml_file = ("%s/%s/%s%s.fxml"):format(root, cfg.resource_roots[1], pkg_path, name)

  local header = (pkg ~= "" and ("package " .. pkg .. ";\n\n") or "") .. "import javafx.fxml.FXML;\n\n"
  if not write(java_file, CONTROLLER:format(header, name)) then return end
  if not write(fxml_file, FXML:format(fqcn)) then return end

  util.edit(fxml_file)
  util.notify(("Created %sController.java and %s.fxml"):format(name, name))
end

--- :JavaFXNew <Name> [package]
function M.create(name, pkg)
  if not name or name == "" then
    return util.notify("Usage: :JavaFXNew <Name> [package]", vim.log.levels.WARN)
  end
  name = name:sub(1, 1):upper() .. name:sub(2)
  if pkg then return create(name, pkg) end
  vim.ui.input({ prompt = "Package: ", default = current_package() }, function(input)
    if input ~= nil then create(name, input) end
  end)
end

return M
