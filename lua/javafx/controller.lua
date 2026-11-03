local util = require("javafx.util")
local fxml = require("javafx.fxml")
local M = {}

local function cfg() return require("javafx").config end

local function buf_text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

local function java_fqcn(buf)
  local pkg = buf_text(buf):match("%f[%w]package%s+([%w_.]+)%s*;")
  local cls = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
  return pkg and (pkg .. "." .. cls) or cls
end

local function find_controller_file(fqcn, root)
  local rel = fqcn:gsub("%.", "/") .. ".java"
  for _, sr in ipairs(cfg().source_roots) do
    local p = root .. "/" .. sr .. "/" .. rel
    if vim.fn.filereadable(p) == 1 then return p end
  end
  -- multi-module fallback
  for _, p in ipairs(vim.fn.globpath(root, "**/" .. rel, false, true)) do
    if not p:find("/target/", 1, true) and not p:find("/build/", 1, true) then
      return p
    end
  end
end

local function find_fxml_for(fqcn, root)
  local hits = {}
  for _, f in ipairs(util.fxml_files(root)) do
    local text = util.read(f)
    if text:find('fx:controller="' .. fqcn .. '"', 1, true)
        or text:find("fx:controller='" .. fqcn .. "'", 1, true) then
      hits[#hits + 1] = f
    end
  end
  return hits
end

local function buf_kind()
  local name = vim.api.nvim_buf_get_name(0)
  if name:match("%.fxml$") then return "fxml" end
  if name:match("%.java$") then return "java" end
end

--- Jump FXML <-> controller.
function M.toggle()
  local root = util.project_root()
  local kind = buf_kind()
  if kind == "fxml" then
    local parsed = fxml.parse(buf_text(0))
    if not parsed.controller then
      return util.notify("No fx:controller in this file", vim.log.levels.WARN)
    end
    local file = find_controller_file(parsed.controller, root)
    if not file then
      return util.notify("Controller not found: " .. parsed.controller, vim.log.levels.WARN)
    end
    util.edit(file)
  elseif kind == "java" then
    util.pick(find_fxml_for(java_fqcn(0), root), "FXML for controller:", util.edit)
  else
    util.notify("Open an .fxml or .java file first", vim.log.levels.WARN)
  end
end

local function inject(buf, parsed)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")

  local fields, handlers = {}, {}
  for _, f in ipairs(parsed.fields) do
    if not text:find("%f[%w_]" .. vim.pesc(f.id) .. "%f[^%w_]%s*;") then
      fields[#fields + 1] = f
    end
  end
  for _, h in ipairs(parsed.handlers) do
    if not text:find("void%s+" .. vim.pesc(h.name) .. "%s*%(") then
      handlers[#handlers + 1] = h
    end
  end
  if #fields == 0 and #handlers == 0 then
    return util.notify("Controller is already up to date")
  end

  -- locate class body
  local class_idx
  for i, l in ipairs(lines) do
    if l:find("%f[%w]class%s+[%w_]+") and not l:match("^%s*//") and not l:match("^%s*%*") then
      class_idx = i
      break
    end
  end
  if not class_idx then
    return util.notify("No class declaration found", vim.log.levels.ERROR)
  end
  local open_idx
  for i = class_idx, #lines do
    if lines[i]:find("{", 1, true) then open_idx = i break end
  end
  local close_idx
  for i = #lines, 1, -1 do
    if lines[i]:match("^%s*}%s*$") then close_idx = i break end
  end
  if not open_idx or not close_idx or close_idx <= open_idx then
    return util.notify("Could not locate class body", vim.log.levels.ERROR)
  end

  -- imports
  local new_imports = {}
  for _, imp in ipairs(fxml.java_imports(parsed, fields, handlers)) do
    if not text:find("import%s+" .. vim.pesc(imp) .. "%s*;") then
      new_imports[#new_imports + 1] = "import " .. imp .. ";"
    end
  end
  local last_import, pkg_idx
  for i, l in ipairs(lines) do
    if l:match("^import%s") then last_import = i end
    if l:match("^%s*package%s") then pkg_idx = i end
  end

  -- apply bottom-to-top so earlier indices stay valid
  if #handlers > 0 then
    local block = {}
    for _, h in ipairs(handlers) do
      vim.list_extend(block, {
        "",
        "    @FXML",
        ("    private void %s(%s event) {"):format(h.name, h.type),
        "        // TODO",
        "    }",
      })
    end
    vim.api.nvim_buf_set_lines(buf, close_idx - 1, close_idx - 1, false, block)
  end

  if #fields > 0 then
    local block = { "" }
    for _, f in ipairs(fields) do
      vim.list_extend(block, { "    @FXML", ("    private %s %s;"):format(f.tag, f.id) })
    end
    vim.api.nvim_buf_set_lines(buf, open_idx, open_idx, false, block)
  end

  if #new_imports > 0 then
    if last_import then
      vim.api.nvim_buf_set_lines(buf, last_import, last_import, false, new_imports)
    elseif pkg_idx then
      local block = { "" }
      vim.list_extend(block, new_imports)
      vim.api.nvim_buf_set_lines(buf, pkg_idx, pkg_idx, false, block)
    else
      table.insert(new_imports, "")
      vim.api.nvim_buf_set_lines(buf, 0, 0, false, new_imports)
    end
  end

  util.notify(("Added %d field(s), %d handler(s)"):format(#fields, #handlers))
end

--- Generate @FXML fields and handler stubs in the controller from its FXML.
function M.inject()
  local root = util.project_root()
  local kind = buf_kind()
  if kind == "fxml" then
    local parsed = fxml.parse(buf_text(0))
    if not parsed.controller then
      return util.notify("No fx:controller in this file", vim.log.levels.WARN)
    end
    local file = find_controller_file(parsed.controller, root)
    if not file then
      return util.notify("Controller not found: " .. parsed.controller, vim.log.levels.WARN)
    end
    util.edit(file)
    inject(vim.api.nvim_get_current_buf(), parsed)
  elseif kind == "java" then
    local buf = vim.api.nvim_get_current_buf()
    util.pick(find_fxml_for(java_fqcn(buf), root), "FXML for controller:", function(f)
      inject(buf, fxml.parse(util.read(f)))
    end)
  else
    util.notify("Open an .fxml or .java file first", vim.log.levels.WARN)
  end
end

return M
