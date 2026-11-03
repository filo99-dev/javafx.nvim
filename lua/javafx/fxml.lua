-- Pure-Lua FXML scanner (no vim API, so it is easy to test).
local M = {}

-- Order matters: first match wins.
local EVENT_TYPES = {
  { "^onAction$",           "ActionEvent",       "javafx.event.ActionEvent" },
  { "^onMouseDrag[EOR]",    "MouseDragEvent",    "javafx.scene.input.MouseDragEvent" },
  { "^onDragDetected$",     "MouseEvent",        "javafx.scene.input.MouseEvent" },
  { "^onMouse",             "MouseEvent",        "javafx.scene.input.MouseEvent" },
  { "^onKey",               "KeyEvent",          "javafx.scene.input.KeyEvent" },
  { "^onDrag",              "DragEvent",         "javafx.scene.input.DragEvent" },
  { "^onScroll",            "ScrollEvent",       "javafx.scene.input.ScrollEvent" },
  { "^onTouch",             "TouchEvent",        "javafx.scene.input.TouchEvent" },
  { "^onSwipe",             "SwipeEvent",        "javafx.scene.input.SwipeEvent" },
  { "^onZoom",              "ZoomEvent",         "javafx.scene.input.ZoomEvent" },
  { "^onRotat",             "RotateEvent",       "javafx.scene.input.RotateEvent" },
  { "^onContextMenu",       "ContextMenuEvent",  "javafx.scene.input.ContextMenuEvent" },
  { "^onInputMethod",       "InputMethodEvent",  "javafx.scene.input.InputMethodEvent" },
}

local function event_type(attr)
  for _, e in ipairs(EVENT_TYPES) do
    if attr:find(e[1]) then return e[2], e[3] end
  end
  return "Event", "javafx.event.Event"
end

local function each_attr(attrs, fn)
  for k, v in attrs:gmatch('([%w_:.]+)%s*=%s*"([^"]*)"') do fn(k, v) end
  for k, v in attrs:gmatch("([%w_:.]+)%s*=%s*'([^']*)'") do fn(k, v) end
end

--- Parse FXML text.
--- @return table { controller, imports, fields = {{id,tag}}, handlers = {{name,type,import}} }
function M.parse(text)
  text = (text:gsub("<!%-%-.-%-%->", ""))
  local res = { imports = {}, fields = {}, handlers = {} }

  for imp in text:gmatch("<%?import%s+([%w_.*]+)%s*%?>") do
    res.imports[#res.imports + 1] = imp
  end

  local seen_f, seen_h = {}, {}
  for tag, attrs in text:gmatch("<(%u[%w_.]*)([^>]*)>") do
    each_attr(attrs, function(k, v)
      if k == "fx:controller" then
        res.controller = v
      elseif k == "fx:id" and not seen_f[v] then
        seen_f[v] = true
        res.fields[#res.fields + 1] = { id = v, tag = tag }
      elseif k:find("^on%u") and v:sub(1, 1) == "#" then
        local name = v:sub(2)
        if not seen_h[name] then
          seen_h[name] = true
          local t, imp = event_type(k)
          res.handlers[#res.handlers + 1] = { name = name, type = t, import = imp }
        end
      end
    end)
  end
  return res
end

--- Java imports needed for the given fields/handlers (sorted, unique).
function M.java_imports(parsed, fields, handlers)
  local used = {}
  for _, f in ipairs(fields) do used[f.tag] = true end

  local set = { ["javafx.fxml.FXML"] = true }
  for _, imp in ipairs(parsed.imports) do
    local last = imp:match("([%w_]+)$")
    if imp:sub(-1) == "*" then
      if #fields > 0 then set[imp] = true end
    elseif used[last] then
      set[imp] = true
    end
  end
  for _, h in ipairs(handlers) do set[h.import] = true end

  local out = {}
  for imp in pairs(set) do out[#out + 1] = imp end
  table.sort(out)
  return out
end

return M
