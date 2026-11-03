-- Completion inside FXML files:
--   * fx:controller="..."  -> project controller class names
--   * <TextF               -> JavaFX components (adds the <?import?> line too)
local M = {}

local uv = vim.uv or vim.loop
local cache = {}
local TTL_MS = 3000

---------------------------------------------------------------------------
-- Project classes
---------------------------------------------------------------------------

local function scan(root)
  local cfg = require("javafx").config
  local suffix = cfg.controller_suffix
  local seen, items = {}, {}
  for _, sr in ipairs(cfg.source_roots) do
    local marker = "/" .. sr .. "/"
    local files = vim.fn.globpath(root, sr .. "/**/*.java", false, true)
    vim.list_extend(files, vim.fn.globpath(root, "**/" .. sr .. "/**/*.java", false, true))
    for _, f in ipairs(files) do
      f = f:gsub("\\", "/")
      if not f:find("/target/", 1, true) and not f:find("/build/", 1, true) then
        local rel = f:match(".*" .. vim.pesc(marker) .. "(.+)%.java$")
        local simple = rel and rel:match("([^/]+)$")
        if simple and simple ~= "module-info" and simple ~= "package-info"
            and (not cfg.controllers_only or simple:sub(-#suffix) == suffix) then
          local fqcn = rel:gsub("/", ".")
          if not seen[fqcn] then
            seen[fqcn] = true
            items[#items + 1] = { fqcn = fqcn, simple = simple }
          end
        end
      end
    end
  end
  table.sort(items, function(a, b)
    local ac, bc = a.simple:find("Controller$") ~= nil, b.simple:find("Controller$") ~= nil
    if ac ~= bc then return ac end
    return a.fqcn < b.fqcn
  end)
  for i, it in ipairs(items) do
    it.sort = ("%05d"):format(i)
  end
  return items
end

function M.classes(root)
  local now = uv.now()
  local c = cache[root]
  if c and now - c.time < TTL_MS then return c.items end
  local items = scan(root)
  cache[root] = { time = now, items = items }
  return items
end

---------------------------------------------------------------------------
-- Context detection
---------------------------------------------------------------------------

--- Inside fx:controller="<prefix> ?
function M.context(before)
  return before:match("fx:controller%s*=%s*[\"']([%w_.$]*)$")
end

--- Typing a tag name right after "<" ?  (not "</", "<?", "<!")
function M.tag_context(before)
  return before:match("<([%w_]*)$")
end

local function ctx_at(before)
  local p = M.context(before)
  if p then return "controller", p end
  p = M.tag_context(before)
  if p then return "tag", p end
end

---------------------------------------------------------------------------
-- <?import ...?> handling
---------------------------------------------------------------------------

--- Where/what to insert to import fqcn, or nil if already imported.
--- @return integer|nil row (0-based), string[]|nil lines
local function import_insertion(lines, fqcn)
  local pkg = fqcn:match("^(.*)%.[^.]+$")
  local text = table.concat(lines, "\n")
  local function has(name)
    return text:find("<%?import%s+" .. vim.pesc(name) .. "%s*%?>") ~= nil
  end
  if has(fqcn) or (pkg and has(pkg .. ".*")) then return nil end

  local tag = "<?import " .. fqcn .. "?>"
  local last_import, decl
  for i, l in ipairs(lines) do
    if l:match("^%s*<%?import%s") then last_import = i end
    if l:match("^%s*<%?xml") then decl = i end
  end
  if last_import then return last_import, { tag } end
  if decl then return decl, { "", tag } end
  return 0, { tag }
end

--- Insert the import into a buffer (used by the omnifunc path).
function M.add_import(buf, fqcn)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local row, new = import_insertion(lines, fqcn)
  if row then vim.api.nvim_buf_set_lines(buf, row, row, false, new) end
end

---------------------------------------------------------------------------
-- Item builders
---------------------------------------------------------------------------

local function range_for(prefix, row, col)
  return {
    start = { line = row, character = col - #prefix },
    ["end"] = { line = row, character = col },
  }
end

local function matches(text, base)
  return base == "" or text:lower():find(base:lower(), 1, true) ~= nil
end

local function match_components(prefix)
  local out = {}
  local p = prefix:lower()
  for _, c in ipairs(require("javafx.components")) do
    if matches(c.name, prefix) then
      local starts = c.name:lower():sub(1, #p) == p
      out[#out + 1] = { name = c.name, pkg = c.pkg, sort = (starts and "0" or "1") .. c.name }
    end
  end
  return out
end

function M.controller_items(prefix, row, col)
  local range = range_for(prefix, row, col)
  local out = {}
  for _, it in ipairs(M.classes(require("javafx.util").project_root())) do
    if matches(it.fqcn, prefix) then
      out[#out + 1] = {
        label = it.fqcn,
        kind = 7, -- Class
        detail = it.simple:find("Controller$") and "controller" or "class",
        filterText = it.fqcn,
        sortText = it.sort,
        textEdit = { range = range, newText = it.fqcn },
      }
    end
  end
  return out
end

function M.component_items(prefix, row, col, lines)
  local range = range_for(prefix, row, col)
  local out = {}
  for _, c in ipairs(match_components(prefix)) do
    local item = {
      label = c.name,
      kind = 7, -- Class
      detail = c.pkg,
      filterText = c.name,
      sortText = c.sort,
      textEdit = { range = range, newText = c.name },
    }
    local irow, ilines = import_insertion(lines, c.pkg .. "." .. c.name)
    if irow then
      item.additionalTextEdits = {
        {
          range = { start = { line = irow, character = 0 }, ["end"] = { line = irow, character = 0 } },
          newText = table.concat(ilines, "\n") .. "\n",
        },
      }
    end
    out[#out + 1] = item
  end
  return out
end

--- Entry point for blink.cmp / nvim-cmp sources.
function M.items_at(before, row, col, buf)
  local kind, prefix = ctx_at(before)
  if kind == "controller" then
    return M.controller_items(prefix, row, col)
  elseif kind == "tag" then
    return M.component_items(prefix, row, col, vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false))
  end
  return {}
end

---------------------------------------------------------------------------
-- omnifunc (<C-x><C-o>) fallback, no completion plugin needed
---------------------------------------------------------------------------

function M.omnifunc(findstart, base)
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local kind, prefix = ctx_at(vim.api.nvim_get_current_line():sub(1, col))
  if findstart == 1 then
    return kind and (col - #prefix) or -3
  end

  local out = {}
  if kind == "controller" then
    for _, it in ipairs(M.classes(require("javafx.util").project_root())) do
      if matches(it.fqcn, base) then
        out[#out + 1] = { word = it.fqcn, abbr = it.fqcn, menu = "[JavaFX]" }
      end
    end
  elseif kind == "tag" then
    for _, c in ipairs(match_components(base)) do
      out[#out + 1] = {
        word = c.name,
        abbr = c.name,
        menu = "[" .. c.pkg .. "]",
        user_data = { javafx_import = c.pkg .. "." .. c.name },
      }
    end
  end
  return out
end

return M
