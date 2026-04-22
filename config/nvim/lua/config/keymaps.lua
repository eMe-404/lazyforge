-- Keymaps are loaded on the VeryLazy event.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- Quick escape from terminal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Center screen after search jumps
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Quick Commit: stage all and commit with a single keymap
map("n", "<leader>gc", function()
  local msg = vim.fn.input("Commit Message: ")
  if msg ~= "" then
    vim.fn.system("git add -A && git commit -m '" .. msg .. "'")
    print("\n Committed: " .. msg)
  end
end, { desc = "Git Quick Commit All" })

-- Search selected text in default browser (<leader>sw in visual mode)
map("v", "<leader>sw", function()
  vim.cmd('normal! "vy')
  local text = vim.fn.trim(vim.fn.getreg("v"))
  local encoded = text:gsub("[^%w%-_%.~]", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  vim.fn.jobstart({ "open", "https://www.google.com/search?q=" .. encoded }, { detach = true })
end, { desc = "Search web for selection" })

-- Yank file:line reference to clipboard (for pasting into OpenCode)
map("v", "<leader>yl", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Get file path relative to git root
  local filepath = vim.fn.expand("%:p")
  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if vim.v.shell_error == 0 then
    filepath = filepath:sub(#git_root + 2) -- strip root + trailing slash
  else
    filepath = vim.fn.expand("%:.") -- fallback: relative to cwd
  end

  local ref = start_line == end_line and (filepath .. ":" .. start_line)
    or (filepath .. ":" .. start_line .. "-" .. end_line)

  vim.fn.setreg("+", ref)
  -- Exit visual mode, then notify
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.notify("Copied: " .. ref, vim.log.levels.INFO)
end, { desc = "Yank file:line ref to clipboard" })

-- Remap <leader>sg: replace Grep with Git Branch Picker
pcall(vim.keymap.del, "n", "<leader>sg")
map("n", "<leader>sg", function()
  Snacks.picker.git_branches()
end, { desc = "Search Git Branches" })
