-- Override LazyVim's default colorscheme with Catppuccin Mocha
-- (matches the Ghostty terminal theme)
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        telescope = { enabled = true },
        which_key = true,
        mini = { enabled = true },
      },
    },
  },

  -- Tell LazyVim to use catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
