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

-- Remap <leader>sg: replace Grep with Git Branch Picker
pcall(vim.keymap.del, "n", "<leader>sg")
map("n", "<leader>sg", function()
  Snacks.picker.git_branches()
end, { desc = "Search Git Branches" })
