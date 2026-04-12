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
