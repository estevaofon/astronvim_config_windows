-- Detect if running on Windows and set a platform-specific path separator
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local path_sep = is_windows and "\\" or "/"

vim.o.background = "light"
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

vim.cmd.colorscheme "solarized"

local lspconfig = require "lspconfig"
lspconfig.pylsp.setup {
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = { "E501", "E126", "E127", "W391" },
        },
      },
    },
  },
}

local function get_local_debugpy()
  local cwd = vim.fn.getcwd()
  -- Check for local virtual environments in order: .venv, .env, then venv.
  local env_paths = {
    cwd .. "\\.venv\\Scripts\\python.exe",
    cwd .. "\\.env\\Scripts\\python.exe",
    cwd .. "\\venv\\Scripts\\python.exe",
  }
  for _, path in ipairs(env_paths) do
    if vim.fn.executable(path) == 1 then return path end
  end
  -- Fallback to Mason's debugpy if no local env is found.
  return "C:\\Users\\estev\\AppData\\Local\\nvim-data\\mason\\packages\\debugpy\\venv\\Scripts\\python.exe"
end

require("dap").adapters.python = {
  type = "executable",
  command = get_local_debugpy(),
  args = { "-m", "debugpy.adapter" },
}

require("dap").configurations.python = {
  {
    name = "Execute Current File",
    type = "python",
    request = "launch",
    program = "${file}", -- This runs the current file directly
    justMyCode = true,
    pythonPath = get_local_debugpy,
  },
  {
    name = "Pytest: Current File",
    type = "python",
    request = "launch",
    module = "pytest", -- Use pytest as the module to run tests
    args = {
      "${file}",
      "-sv", -- show output
      "--log-cli-level=INFO", -- log level (optional)
      "--log-file=test_out.log", -- log file (optional)
    },
    console = "integratedTerminal",
    cwd = vim.fn.getcwd(),
    justMyCode = false, -- debugger will step into libraries if needed
    subProcess = true,
    pythonPath = get_local_debugpy,
  },
}

vim.keymap.set("n", "<F12>", require("dap").step_into, { desc = "Step Into Function" })
vim.keymap.set("n", "<F6>", require("dap").terminate, { desc = "Stop Debugging" })

-- Disable the default Tab mapping for Copilot and remap its accept action.
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>a", ":lua print(vim.fn.expand('%:p'))<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gp", ":GitSigns preview_hunk<CR>", {})

-- Function to set the Python environment for DAP (using platform-specific paths)
local function set_python_env()
  local cwd = vim.fn.getcwd()
  local bin_folder = is_windows and "Scripts"
  local exe = is_windows and "python.exe" or "python"
  local venv_paths = {
    cwd .. path_sep .. ".venv" .. path_sep .. path_sep .. exe,
    cwd .. path_sep .. "venv" .. path_sep .. path_sep .. exe,
    cwd .. path_sep .. ".env" .. path_sep .. path_sep .. exe,
  }
  for _, path in ipairs(venv_paths) do
    if vim.fn.executable(path) == 1 then
      vim.g.python3_host_prog = path
      return path
    end
  end
  return nil
end

set_python_env()

-- Use the environment variable HOME if available; otherwise, use USERPROFILE (common on Windows)
local HOME = os.getenv "HOME" or os.getenv "USERPROFILE"

local M = {}
M.store_breakpoints = function(clear)
  local dap_cache_dir = vim.fn.stdpath "cache" .. path_sep .. "dap"
  vim.fn.mkdir(dap_cache_dir, "p")
  local breakpoints_file = dap_cache_dir .. path_sep .. "breakpoints.json"

  if vim.fn.filereadable(breakpoints_file) == 0 then
    local f = io.open(breakpoints_file, "w")
    f:write "{}"
    f:close()
  end

  local load_bps_raw = io.open(breakpoints_file, "r"):read "*a"
  if load_bps_raw == "" then load_bps_raw = "{}" end

  local bps = vim.fn.json_decode(load_bps_raw)
  local breakpoints_by_buf = require("dap.breakpoints").get()
  if clear then
    for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
      local file_path = vim.api.nvim_buf_get_name(bufrn)
      if bps[file_path] ~= nil then bps[file_path] = {} end
    end
  else
    for buf, buf_bps in pairs(breakpoints_by_buf) do
      bps[vim.api.nvim_buf_get_name(buf)] = buf_bps
    end
  end
  local fp = io.open(breakpoints_file, "w")
  local final = vim.fn.json_encode(bps)
  fp:write(final)
  fp:close()
end

M.load_breakpoints = function()
  local dap_cache_dir = vim.fn.stdpath "cache" .. path_sep .. "dap"
  local breakpoints_file = dap_cache_dir .. path_sep .. "breakpoints.json"
  local fp = io.open(breakpoints_file, "r")
  if fp == nil then
    print "No breakpoints found."
    return
  end
  local content = fp:read "*a"
  local bps = vim.fn.json_decode(content)
  local loaded_buffers = {}
  local found = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local file_name = vim.api.nvim_buf_get_name(buf)
    if bps[file_name] ~= nil and next(bps[file_name]) then found = true end
    loaded_buffers[file_name] = buf
  end
  if not found then return end
  for path, buf_bps in pairs(bps) do
    for _, bp in pairs(buf_bps) do
      local line = bp.line
      local opts = {
        condition = bp.condition,
        log_message = bp.logMessage,
        hit_condition = bp.hitCondition,
      }
      require("dap.breakpoints").set(opts, tonumber(loaded_buffers[path]), line)
    end
  end
end

local dap_breakpoints = M

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function() dap_breakpoints.load_breakpoints() end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function() dap_breakpoints.store_breakpoints(false) end,
})

vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>lg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true, silent = true })

local function search_replace_prompt()
  vim.ui.input({ prompt = "Enter word to search: " }, function(search)
    if not search or search == "" then
      print "Search term is empty."
      return
    end
    vim.ui.input({ prompt = "Enter replacement word: " }, function(replacement)
      if replacement == nil then
        print "Replacement term is empty."
        return
      end
      local escaped_search = vim.fn.escape(search, "/")
      local escaped_replacement = vim.fn.escape(replacement, "/")
      local cmd = string.format("%%s/\\<%s\\>/%s/g", escaped_search, escaped_replacement)
      vim.cmd(cmd)
      print(string.format("Replaced '%s' with '%s' in the entire file.", search, replacement))
    end)
  end)
end

vim.api.nvim_create_user_command("SearchReplace", search_replace_prompt, {})

vim.keymap.set("n", "<leader>sr", search_replace_prompt, { desc = "Search and Replace" })
vim.keymap.set("n", "<F4>", require("dap.ui.widgets").hover, { silent = true })

local dapui = require "dapui"
dapui.setup {
  auto_open = true,
  auto_close = false,
}

local dap = require "dap"
dap.listeners.before.event_terminated["dapui_config"] = function() end
dap.listeners.before.event_exited["dapui_config"] = function() end

dap.listeners.before.event_initialized["save_buffer"] = function(session)
  vim.g.last_dap_buffer = vim.api.nvim_get_current_buf()
end

vim.keymap.set("n", "<leader>dq", function()
  dapui.close()
  if vim.g.last_dap_buffer then
    vim.api.nvim_set_current_buf(vim.g.last_dap_buffer)
  else
    print "No original file recorded."
  end
end, { desc = "Return to file where DAP was issued" })

vim.keymap.set(
  "n",
  "<leader>cn",
  function() require("notify").dismiss { silent = true, pending = true } end,
  { desc = "Dismiss all notifications" }
)

vim.keymap.set({ "n", "x" }, "<leader>c", ":s/^\\(\\s*\\)/\\1# /<CR>", { silent = true })
vim.keymap.del("n", "<C-q>")
vim.api.nvim_set_keymap("n", "<C-q>", "<C-v>", { noremap = true, silent = true })

vim.keymap.set(
  "n",
  "<leader>ss",
  ":mksession! " .. vim.fn.stdpath "config" .. path_sep .. "session" .. path_sep .. "mysession.vim<CR>",
  { silent = true }
)
vim.keymap.set(
  "n",
  "<leader>sl",
  ":source " .. vim.fn.stdpath "config" .. path_sep .. "session" .. path_sep .. "mysession.vim<CR>",
  { silent = true }
)

local dap = require "dap"

vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })

vim.api.nvim_create_user_command("InsertLambdaSnippet", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, {
    'if __name__ == "__main__":',
    "    event = {}",
    "    lambda_handler(event, context=None)",
  })
end, {})

vim.api.nvim_set_keymap("n", "<leader>w", ":InsertLambdaSnippet<CR>", { noremap = true, silent = true })
