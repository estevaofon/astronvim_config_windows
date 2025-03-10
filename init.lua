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

-- local lspconfig = require "lspconfig"
-- lspconfig.pylsp.setup {
--   settings = {
--     pylsp = {
--       plugins = {
--         pycodestyle = {
--           ignore = { "E501", "E126", "E127", "W391" },
--         },
--       },
--     },
--   },
-- }

-- Define a global config variable
_G.my_pylsp_config = {
  pylsp = {
    plugins = {
      pycodestyle = { ignore = { "E501", "E126", "E127", "W391" } },
      pyflakes = { enabled = true }, -- initial state
    },
  },
}

local lspconfig = require "lspconfig"
lspconfig.pylsp.setup {
  settings = _G.my_pylsp_config,
}

-- Create a command to toggle pyflakes and restart the server
vim.api.nvim_create_user_command("TogglePyflakes", function()
  -- Toggle the pyflakes setting in the global config
  _G.my_pylsp_config.pylsp.plugins.pyflakes.enabled = not _G.my_pylsp_config.pylsp.plugins.pyflakes.enabled

  print("Pyflakes is now " .. (_G.my_pylsp_config.pylsp.plugins.pyflakes.enabled and "enabled" or "disabled"))

  -- Restart the server so it picks up the updated config
  vim.cmd "LspRestart"
end, {})

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
      "--no-header", -- Suppress header output
      "--no-summary", -- Suppress summary output
    },
    console = "integratedTerminal",
    cwd = vim.fn.getcwd(),
    justMyCode = true, -- debugger will step into libraries if needed
    subProcess = false,
    pythonPath = get_local_debugpy,
  },
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

vim.keymap.set("n", "<F2>", ":bp<CR>", { desc = "Previous Breakpoint" })
vim.keymap.set("n", "<F3>", ":bn<CR>", { desc = "Next Breakpoint" })
vim.keymap.set("n", "<F12>", require("dap").step_into, { desc = "Step Into Function" })
vim.keymap.set("n", "<F6>", require("dap").terminate, { desc = "Stop Debugging" })

function _G.safe_bdelete(buf)
  local buf_to_delete = buf or vim.api.nvim_get_current_buf()
  local bufs = vim.fn.getbufinfo { buflisted = 1 }
  if #bufs == 1 then
    -- Se houver apenas um buffer listado, cria um novo buffer vazio
    vim.cmd "enew"
  else
    -- Se existir um buffer alternativo (diferente do que vamos fechar), muda para ele
    local alt_buf = vim.fn.bufnr "#"
    if alt_buf > 0 and alt_buf ~= buf_to_delete then
      vim.cmd "buffer #"
    else
      -- Caso não haja um buffer alternativo válido, alterna para o buffer anterior
      vim.cmd "bprevious"
    end
  end
  -- Deleta o buffer que originalmente estava ativo (ou o passado como argumento)
  vim.cmd("bdelete " .. buf_to_delete)
end

vim.api.nvim_set_keymap("n", "<leader>bd", ":lua safe_bdelete()<CR>", { noremap = true, silent = true })

function _G.close_all_buffers()
  vim.cmd "silent! %bdelete"
  vim.cmd "Neotree toggle"
end

vim.api.nvim_set_keymap("n", "<leader>ba", ":lua close_all_buffers()<CR>", { noremap = true, silent = true })

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

require("telescope").setup {
  defaults = {
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--fixed-strings", -- This flag makes ripgrep treat the pattern as a literal string.
      "--smart-case",
    },
  },
}

vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>lg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true, silent = true })

local function search_replace_prompt()
  vim.ui.input({ prompt = "Enter word to search: " }, function(search)
    if not search or search == "" then
      print "Search term is empty."
      return
    end
    vim.ui.input({ prompt = "Enter replacement word (leave empty to remove): " }, function(replacement)
      if replacement == nil then replacement = "" end
      -- Escape both '/' and '\' for the search string
      local escaped_search = vim.fn.escape(search, "/\\")
      local escaped_replacement = vim.fn.escape(replacement, "/\\")
      -- Use \V to force literal mode
      local cmd = string.format("%%s/\\V%s/%s/g", escaped_search, escaped_replacement)
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

-- Eval var under cursor
vim.keymap.set("n", "<F1>", function() require("dapui").eval(nil, { enter = true }) end)

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

if vim.loop.os_uname().sysname == "Windows_NT" then
  vim.opt.shell = "powershell"
  vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

require("nvim-dap-virtual-text").setup {
  enabled = true, -- enable this plugin (the default)
  enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
  highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
  highlight_new_as_changed = true, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
  show_stop_reason = true, -- show stop reason when stopped for exceptions
  commented = false, -- prefix virtual text with comment string
  only_first_definition = false, -- only show virtual text at first definition (if there are multiple)
  all_references = false, -- show virtual text on all all references of the variable (not only definitions)
  clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
  --- A callback that determines how a variable is displayed or whether it should be omitted
  --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
  --- @param buf number
  --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
  --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
  --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
  --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
  display_callback = function(variable, buf, stackframe, node, options)
    -- by default, strip out new line characters
    if options.virt_text_pos == "inline" then
      return " = " .. variable.value:gsub("%s+", " ")
    else
      return variable.name .. " = " .. variable.value:gsub("%s+", " ")
    end
  end,
  -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
  virt_text_pos = "eol",

  -- experimental features:
  all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
  virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
  virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
  -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
}

-- Disable diagnostics when a debug session starts
dap.listeners.after.event_initialized["disable_diagnostics"] = function()
  vim.diagnostic.disable()
  vim.cmd "Neotree close"
end

-- Re-enable diagnostics when the session terminates or exits
dap.listeners.before.event_terminated["enable_diagnostics"] = function() vim.diagnostic.enable() end

dap.listeners.before.event_exited["enable_diagnostics"] = function() vim.diagnostic.enable() end

dap.listeners.after.event_stopped["store_frame_id"] = function(session, event)
  session:request("stackTrace", { threadId = event.threadId, startFrame = 0, levels = 1 }, function(err, response)
    if not err and response and response.stackFrames and #response.stackFrames > 0 then
      vim.g.current_frame_id = response.stackFrames[1].id
      print("Stored current frame id: " .. vim.g.current_frame_id)
    end
  end)
end

local function evaluate_expr(session, expr, frameId, callback)
  session:request("evaluate", { expression = expr, context = "hover", frameId = frameId }, callback)
end

local function fallback_evaluate(session, expr, callback)
  session:request("threads", {}, function(err, threads_response)
    if err then
      print("Error getting threads: " .. (err.message or "unknown error"))
      return
    end
    if threads_response and threads_response.threads and #threads_response.threads > 0 then
      local threadId = threads_response.threads[1].id
      session:request("stackTrace", { threadId = threadId, startFrame = 0, levels = 1 }, function(err, stack_response)
        if err then
          print("Error getting stack trace: " .. (err.message or "unknown error"))
          return
        end
        if stack_response and stack_response.stackFrames and #stack_response.stackFrames > 0 then
          local newFrameId = stack_response.stackFrames[1].id
          print("Fallback: got frame id " .. newFrameId)
          evaluate_expr(session, expr, newFrameId, callback)
        else
          print "No stack frames available"
        end
      end)
    else
      print "No threads available"
    end
  end)
end

local function copy_variable_value()
  print "copy_variable_value triggered"

  local expr = vim.fn.expand "<cword>"
  print("Variable under cursor: " .. expr)
  if expr == "" then
    print "No variable found under cursor"
    return
  end

  local session = dap.session()
  if not session then
    print "No active debug session"
    return
  else
    print "Active debug session found"
  end

  -- Use JSON serialization so that the output is a valid JSON string.
  local wrapped_expr = string.format('__import__("json").dumps(%s, default=str, ensure_ascii=False)', expr)
  print("Evaluating: " .. wrapped_expr)

  local function handle_evaluation(err, response)
    if err then
      print("Error evaluating variable: " .. (err.message or "unknown error"))
      return
    end
    if not response or not response.result then
      print("No result returned for variable: " .. expr)
      return
    end

    local result = response.result
    print("Raw evaluation result: " .. result)

    -- Write the JSON string into a new scratch buffer.
    vim.cmd "enew"
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false

    -- Save to a file on the desktop.
    local temp_file = "D:\\OneDrive\\Desktop\\variable_value.txt"
    local file = io.open(temp_file, "w")
    file:write(result)
    file:close()

    -- Call the internal program: json-to-dict
    local command = 'json-to-dict -i "D:\\OneDrive\\Desktop\\variable_value.txt" -o "D:\\OneDrive\\Desktop\\temp.txt"'
    local success = os.execute(command)
    if success then
      print "json-to-dict command executed successfully"
    else
      print "Failed to execute json-to-dict command"
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { result })
    vim.cmd "setlocal filetype=json"
  end

  local frameId = vim.g.current_frame_id
  if frameId then
    evaluate_expr(session, wrapped_expr, frameId, function(err, response)
      if err then
        print("Error evaluating with stored frame id: " .. (err.message or "unknown error"))
        fallback_evaluate(session, wrapped_expr, handle_evaluation)
      else
        handle_evaluation(err, response)
      end
    end)
  else
    print "No frame id stored; trying fallback evaluation"
    fallback_evaluate(session, wrapped_expr, handle_evaluation)
  end
end

vim.keymap.set("n", "<F8>", copy_variable_value, { silent = false, desc = "Copy variable value to new buffer" })

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function() require("persistent-breakpoints.api").reload_breakpoints() end,
})

-- Define a function to prompt for a literal search string
local function literal_search_prompt()
  vim.ui.input({ prompt = "Enter search string: " }, function(input)
    if not input or input == "" then
      print "Search term is empty."
      return
    end
    -- Prepend \V to force literal search (no regex meta characters)
    local literal_pattern = "\\V" .. input
    -- Set the search register so that / uses this literal pattern
    vim.fn.setreg("/", literal_pattern)
    -- Jump to the next occurrence
    vim.cmd "normal! n"
  end)
end

-- Create a user command for convenience
vim.api.nvim_create_user_command("LiteralSearch", literal_search_prompt, {})

-- Optionally, map a key (here <leader>ls) to invoke the prompt
vim.api.nvim_set_keymap("n", "<leader>ls", ":LiteralSearch<CR>", { noremap = true, silent = true })

require("regexescape").setup {
  keymap = "<leader>e", -- change as desired
}
