-- Local editor plugin overrides / additions
-- Drop new plugin specs here; each file in lua/plugins/ is auto-loaded.
return {
  -- Example: disable a LazyVim default plugin
  -- { "folke/flash.nvim", enabled = false },

  -- disable autocompletion
  { "hrsh7th/nvim-cmp", enabled = false },

  -- disable markdownlint (too noisy when reviewing external docs)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },

  -- bash-language-server + shfmt (no LazyVim extra exists for shell)
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "bash-language-server", "shfmt" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },
}
