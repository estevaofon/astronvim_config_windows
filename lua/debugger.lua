-- debugger.lua
local M = {}

-- Platform detection
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local path_sep = is_windows and "\\" or "/"

-- Find appropriate Python executable
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

-- Set the Python environment for DAP (using platform-specific paths)
local function set_python_env()
  local cwd = vim.fn.getcwd()
  local bin_folder = is_windows and "Scripts" or "bin"
  local exe = is_windows and "python.exe" or "python"
  local venv_paths = {
    cwd .. path_sep .. ".venv" .. path_sep .. bin_folder .. path_sep .. exe,
    cwd .. path_sep .. "venv" .. path_sep .. bin_folder .. path_sep .. exe,
    cwd .. path_sep .. ".env" .. path_sep .. bin_folder .. path_sep .. exe,
  }
  for _, path in ipairs(venv_paths) do
    if vim.fn.executable(path) == 1 then
      vim.g.python3_host_prog = path
      return path
    end
  end
  return nil
end

-- Check if debugpy is installed
local function check_debugpy_installed()
  local python = get_local_debugpy()
  -- Ensure the Python executable exists.
  if vim.fn.executable(python) == 0 then
    vim.notify("Python executable not found: " .. python, vim.log.levels.ERROR)
    return false
  end
  -- Attempt to import debugpy.
  local output = vim.fn.system(python .. ' -c "import debugpy"')
  if vim.v.shell_error ~= 0 then
    vim.notify("debugpy is not installed in the environment (" .. python .. ")", vim.log.levels.INFO)
    return false
  end
  return true
end

function M.setup()
  local dap = require "dap"
  local dapui = require "dapui"

  -- Configure Python adapter
  dap.adapters.python = {
    type = "executable",
    command = get_local_debugpy(),
    args = { "-m", "debugpy.adapter" },
  }

  -- Configure Python configurations
  dap.configurations.python = {
    {
      name = "Execute Current File",
      type = "python",
      request = "launch",
      program = "${file}", -- This runs the current file directly
      justMyCode = false,
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
      },
      console = "integratedTerminal",
      cwd = vim.fn.getcwd(),
      justMyCode = false, -- debugger will step into libraries if needed
      subProcess = false,
      pythonPath = get_local_debugpy,
    },
  }

  -- Initialize and configure dapui
  dapui.setup {
    auto_open = true,
    auto_close = false,
  }

  -- Setup DAP event listeners
  dap.listeners.before.event_terminated["dapui_config"] = function() end
  dap.listeners.before.event_exited["dapui_config"] = function() end

  dap.listeners.before.event_initialized["save_buffer"] = function(session)
    vim.g.last_dap_buffer = vim.api.nvim_get_current_buf()
  end

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

  -- Setup virtual text for DAP
  require("nvim-dap-virtual-text").setup {
    enabled = true, -- enable this plugin (the default)
    enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle
    highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged
    highlight_new_as_changed = true, -- highlight new variables in the same way as changed variables
    show_stop_reason = true, -- show stop reason when stopped for exceptions
    commented = false, -- prefix virtual text with comment string
    only_first_definition = false, -- only show virtual text at first definition
    all_references = false, -- show virtual text on all references of the variable
    clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
    display_callback = function(variable, buf, stackframe, node, options)
      -- by default, strip out new line characters
      if options.virt_text_pos == "inline" then
        return " = " .. variable.value:gsub("%s+", " ")
      else
        return variable.name .. " = " .. variable.value:gsub("%s+", " ")
      end
    end,
    virt_text_pos = "eol",
    all_frames = false,
    virt_lines = false,
    virt_text_win_col = nil,
  }

  -- Set key mappings
  vim.keymap.set("n", "<F1>", function() dapui.eval(nil, { enter = true }) end)

  vim.keymap.set("n", "<leader>dq", function()
    dapui.close()
    if vim.g.last_dap_buffer then
      vim.api.nvim_set_current_buf(vim.g.last_dap_buffer)
    else
      print "No original file recorded."
    end
  end, { desc = "Return to file where DAP was issued" })

  -- Run initialization checks
  check_debugpy_installed()
  set_python_env()
end

return M
