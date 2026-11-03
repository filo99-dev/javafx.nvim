local util = require("javafx.util")
local M = {}

local job

local function start_term(cmd, opts)
  if vim.fn.has("nvim-0.11") == 1 then
    opts.term = true
    return vim.fn.jobstart(cmd, opts)
  end
  return vim.fn.termopen(cmd, opts)
end

function M.stop()
  if job then
    pcall(vim.fn.jobstop, job)
    job = nil
    util.notify("Stopped")
  end
end

function M.run()
  local cfg = require("javafx").config
  local root = util.project_root()
  local cmd = util.build_cmd(root, cfg)
  if not cmd then
    return util.notify("No pom.xml or build.gradle(.kts) found", vim.log.levels.ERROR)
  end
  if cfg.save_before_run then vim.cmd("silent! wall") end
  if job then M.stop() end

  vim.cmd(cfg.run_split)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  job = start_term(cmd, {
    cwd = root,
    on_exit = function(_, code)
      job = nil
      vim.schedule(function()
        util.notify("Exited with code " .. code, code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
      end)
    end,
  })
  vim.cmd("normal! G")
end

return M
