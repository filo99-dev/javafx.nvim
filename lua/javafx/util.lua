local M = {}
local uv = vim.uv or vim.loop

function M.notify(msg, level)
  vim.notify("[javafx] " .. msg, level or vim.log.levels.INFO)
end

local MARKERS = {
  "pom.xml", "build.gradle", "build.gradle.kts",
  "settings.gradle", "settings.gradle.kts",
}

function M.project_root()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = uv.cwd()
  elseif vim.fn.isdirectory(start) == 0 then
    start = vim.fs.dirname(start)
  end
  local found = vim.fs.find(MARKERS, { path = start, upward = true })[1]
  return found and vim.fs.dirname(found) or uv.cwd()
end

local function exists(p)
  return vim.fn.filereadable(p) == 1
end

-- Returns a command list for running the app, or nil.
function M.build_cmd(root, cfg)
  local win = vim.fn.has("win32") == 1
  if exists(root .. "/pom.xml") then
    local wrapper = root .. (win and "/mvnw.cmd" or "/mvnw")
    return { exists(wrapper) and wrapper or "mvn", cfg.maven_goal }
  end
  if exists(root .. "/build.gradle") or exists(root .. "/build.gradle.kts") then
    local wrapper = root .. (win and "/gradlew.bat" or "/gradlew")
    return { exists(wrapper) and wrapper or "gradle", cfg.gradle_task }
  end
  return nil
end

function M.read(path)
  return table.concat(vim.fn.readfile(path), "\n")
end

-- All .fxml files under root, ignoring build output.
function M.fxml_files(root)
  local out = {}
  for _, f in ipairs(vim.fn.globpath(root, "**/*.fxml", false, true)) do
    if not f:find("/target/", 1, true) and not f:find("/build/", 1, true)
        and not f:find("/.git/", 1, true) and not f:find("/node_modules/", 1, true) then
      out[#out + 1] = f
    end
  end
  return out
end

function M.pick(items, prompt, cb)
  if #items == 0 then
    return M.notify("Nothing found", vim.log.levels.WARN)
  elseif #items == 1 then
    return cb(items[1])
  end
  vim.ui.select(items, { prompt = prompt }, function(choice)
    if choice then cb(choice) end
  end)
end

function M.edit(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
