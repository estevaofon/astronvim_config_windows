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

-- ── Sessão & swap (registrados aqui no init, que roda ANTES do VimEnter, p/ garantir o timing) ──
-- Nunca deixar um swap file (.swp) travar a abertura de um arquivo (E325): abre "edit anyway".
vim.api.nvim_create_autocmd("SwapExists", {
  desc = "Abrir ignorando swap file (sem prompt E325)",
  callback = function() vim.v.swapchoice = "e" end,
})
-- Restaura a última sessão (resession) ao abrir o nvim. Aceita abrir uma PASTA (ex.: `nvim .`);
-- só pula quando você abre um ARQUIVO específico (`nvim x.py`). "Last Session" independe do cwd.
local function _restore_last_session()
  local n = vim.fn.argc(-1)
  local should = n == 0 or (n == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)
  if not should then return end
  local ok, resession = pcall(require, "resession")
  if ok then resession.load("Last Session", { silence_errors = true }) end
end
if vim.v.vim_did_enter == 1 then
  _restore_last_session()
else
  vim.api.nvim_create_autocmd("VimEnter", { once = true, nested = true, callback = _restore_last_session })
end

-- vim.cmd.colorscheme "solarized"
vim.cmd.colorscheme "catppuccin-mocha"
-- vim.cmd.colorscheme "tokyonight-night"

-- pylsp is configured through AstroLSP (lua/plugins/astrolsp.lua) and installed via Mason
-- (lua/plugins/mason.lua). `_G.my_pylsp_config` now lives in astrolsp.lua so `:TogglePyflakes`
-- keeps working.

-- require("persistent-breakpoints").setup {
--   load_breakpoints_event = { "BufReadPost" },
-- }

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
-- Save breakpoints to file automatically.
-- Delete F9 keymap to avoid conflicts with persistent-breakpoints.
vim.keymap.del("n", "<F9>")
-- keymap("n", "<F9>", "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>", opts)
vim.keymap.set(
  "n",
  "<F9>",
  function() require("dap").toggle_breakpoint() end,
  { noremap = true, silent = true, desc = "Toggle breakpoint" }
)

vim.keymap.set("n", "<F3>", ":bn<CR>", { desc = "Next Breakpoint" })
vim.keymap.set("n", "<F12>", require("dap").step_into, { desc = "Step Into Function" })
-- Step out
vim.keymap.set("n", "<F2>", require("dap").step_out, { desc = "Step Out of Function" })
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

-- In your init.lua, add this line where you want to set up the base64 functionality
require("utils.base64").setup()
require("utils.search").setup()
require("utils.json_utils").setup()
require("utils.python_path").setup()
require("utils.debugger").setup()
require("utils.my_utils").setup()
require("utils.markdown-preview").setup()
require("utils.path_utils").setup()
require("utils.help_me").setup()

-- require("ailite").setup {
--   assistant_name = "AiLite",
--   assistant_prefix = "AiLite: ",
--   max_tokens = 8192,
--   context = {
--     max_tokens_per_message = 6000, -- ajuste o valor conforme necessário
--   },
--   model = "claude-sonnet-4-20250514",
-- }
require("nox").setup()
