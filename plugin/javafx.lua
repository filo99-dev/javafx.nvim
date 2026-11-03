if vim.g.loaded_javafx_nvim then
  return
end
vim.g.loaded_javafx_nvim = true

vim.filetype.add({ extension = { fxml = "xml" } })

require("javafx.commands").register()

local group = vim.api.nvim_create_augroup("javafx_nvim", { clear = true })

-- <C-x><C-o> completion (controller classes and components), no plugin needed.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "xml",
  callback = function(ev)
    if not vim.api.nvim_buf_get_name(ev.buf):match("%.fxml$") then return end
    vim.bo[ev.buf].omnifunc = "v:lua.require'javafx.complete'.omnifunc"
    -- omnifunc can't carry extra edits, so add the <?import?> line on accept.
    vim.api.nvim_create_autocmd("CompleteDone", {
      group = group,
      buffer = ev.buf,
      callback = function()
        local item = vim.v.completed_item
        local ud = type(item) == "table" and item.user_data or nil
        if type(ud) == "table" and ud.javafx_import then
          require("javafx.complete").add_import(ev.buf, ud.javafx_import)
        end
      end,
    })
  end,
})

-- nvim-cmp users: make the "javafx" source available once cmp is loaded.
vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  once = true,
  callback = function()
    vim.schedule(function() require("javafx.cmp").register() end)
  end,
})
