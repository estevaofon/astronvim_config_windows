-- Detect if running on Windows and set a platform-specific path separator
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local path_sep = is_windows and "\\" or "/"

-- vim.o.background = "light"
-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- BE CAUTIOUS editing this file and proceed at your own risk.

local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. path_sep .. "lazy" .. path_sep .. "lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Validate that lazy is available
if not pcall(require, "lazy") then
  vim.api.nvim_echo({
    { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" },
    { "Press any key to exit...", "MoreMsg" },
  }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

-- vim.cmd.colorscheme "solarized"
vim.cmd.colorscheme "catppuccin-mocha"
-- vim.cmd.colorscheme "tokyonight-night"

-- Define a global config variable
_G.my_pylsp_config = {
  pylsp = {
    plugins = {
      pycodestyle = { ignore = { "E501", "E126", "E127", "W391", "W504" } },
      pyflakes = { enabled = true }, -- initial state
    },
  },
}

local lspconfig = require "lspconfig"
lspconfig.pylsp.setup {
  settings = _G.my_pylsp_config,
}

require("persistent-breakpoints").setup {
  load_breakpoints_event = { "BufReadPost" },
}

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
-- Save breakpoints to file automatically.
-- Delete F9 keymap to avoid conflicts with persistent-breakpoints.
vim.keymap.del("n", "<F9>")
keymap("n", "<F9>", "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>", opts)

vim.keymap.set("n", "<F3>", ":bn<CR>", { desc = "Next Breakpoint" })
vim.keymap.set("n", "<F12>", require("dap").step_into, { desc = "Step Into Function" })
vim.keymap.set("n", "<F6>", require("dap").terminate, { desc = "Stop Debugging" })

vim.api.nvim_set_keymap("n", "<leader>bd", ":lua safe_bdelete()<CR>", { noremap = true, silent = true })

-- Disable the default Tab mapping for Copilot and remap its accept action.
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-l>", "copilot#Accept('<CR>')", { expr = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>a", ":lua print(vim.fn.expand('%:p'))<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gp", ":GitSigns preview_hunk<CR>", {})

-- Use the environment variable HOME if available; otherwise, use USERPROFILE (common on Windows)

vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true, silent = true })

vim.keymap.set("n", "<F4>", require("dap.ui.widgets").hover, { silent = true })

vim.keymap.set(
  "n",
  "<leader>cn",
  function() require("notify").dismiss { silent = true, pending = true } end,
  { desc = "Dismiss all notifications" }
)

vim.keymap.del("n", "<C-q>")
vim.api.nvim_set_keymap("n", "<C-q>", "<C-v>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function() require("persistent-breakpoints.api").reload_breakpoints() end,
})

require("regexescape").setup {
  keymap = "<leader>e", -- change as desired
}

require("toggleterm").setup {
  direction = "vertical", -- this makes the terminal open vertically
  size = 80, -- adjust the width as needed
}
-- In your init.lua, add this line where you want to set up the base64 functionality
require("base64").setup()
require("search").setup()
require("json_utils").setup()
require("debugger").setup()
require("my_utils").setup()

_G.search_replace_prompt = require("search").search_replace_prompt
_G.literal_search_prompt = require("search").literal_search_prompt

-- Create a user command for convenience
vim.api.nvim_create_user_command("LiteralSearch", _G.literal_search_prompt, {})
-- Optionally, map a key (here <leader>ls) to invoke the prompt
vim.api.nvim_set_keymap("n", "<leader>ls", ":LiteralSearch<CR>", { noremap = true, silent = true })

vim.api.nvim_create_user_command("SearchReplace", _G.search_replace_prompt, {})

vim.keymap.set("n", "<leader>sr", _G.search_replace_prompt, { desc = "Search and Replace" })
