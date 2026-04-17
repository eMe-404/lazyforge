-- Autocmds are loaded on the VeryLazy event.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = vim.api.nvim_create_augroup("yaer_yank_highlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-save on focus loss and when leaving insert/normal mode
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
  desc = "Auto-save buffer",
  group = vim.api.nvim_create_augroup("yaer_autosave", { clear = true }),
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Disable spellcheck (LazyVim enables it for markdown by default)
vim.api.nvim_create_autocmd("FileType", {
  desc = "Disable spellcheck",
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
