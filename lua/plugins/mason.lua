-- Customize Mason plugins

---@type LazySpec
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = {
      ensure_installed = {
        "lua_ls",
        -- NOTE: pylsp is intentionally NOT installed via Mason here -- its pypi install fails on
        -- this machine. It runs from a dedicated venv configured in lua/plugins/astrolsp.lua.
        -- add more arguments for adding more language servers
      },
    },
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = {
      ensure_installed = {
        "stylua",
        -- add more arguments for adding more null-ls sources
      },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = {
      ensure_installed = {
        "python",
        -- add more arguments for adding more debuggers
      },
    },
  },
  -- auto-session foi REMOVIDO: o auto-save dele vivia congelando a sessão (ficava presa numa
  -- versão antiga) e ainda brigava com o resession nativo do AstroNvim. As sessões agora são
  -- 100% do resession: ele salva o dirsession ao sair, e restauramos no boot via autocmd
  -- (restore_dir_session) em lua/plugins/astrocore.lua.
  {
    "tpope/vim-fugitive",
  },
  {
    "estevaofon/ailite.nvim",
  },
  {
    "estevaofon/nox.nvim",
    ft = "nox", -- Lazy load on Nox files
  },
}
