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

  -- remove prettier as YAML formatter (it rewrites quotes, adds blank lines)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        yaml = {},
        markdown = {},
        json = {},
        jsonc = {},
        javascript = {},
        javascriptreact = {},
        typescript = {},
        typescriptreact = {},
        css = {},
        scss = {},
        less = {},
        html = {},
        graphql = {},
      },
    },
  },

  -- bash-language-server + shfmt (no LazyVim extra exists for shell)
  {
    "mason-org/mason.nvim",
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
