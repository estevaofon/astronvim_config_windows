-- Create a module
local M = {}

-- Function to set Python path based on current project
function M.set_python_path()
  -- Get the current working directory
  local cwd = vim.fn.getcwd()

  -- Convert to lowercase for case-insensitive comparison
  local cwd_lower = string.lower(cwd)

  -- Check which project we're in
  if string.find(cwd_lower, "tcloud%-api") then
    -- We're in tcloud-api project
    local python_path = {
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-api\\src",
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-api\\src\\stepfunction",
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-api",
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-codeartifact",
    }

    -- Convert to string with path separator
    local path_str = table.concat(python_path, ";")

    -- Set PYTHONPATH environment variable
    vim.env.PYTHONPATH = path_str
    -- print "Set PYTHONPATH for tcloud-api project"
    vim.notify "Set PYTHONPATH for tcloud-api project"
  elseif string.find(cwd_lower, "tcloud%-monitors%-api") then
    -- We're in tcloud-monitors-api project
    local python_path = {
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-monitors-api\\src",
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-monitors-api",
      "D:\\OneDrive\\Documentos\\TOTVS\\tcloud-codeartifact",
    }

    -- Convert to string with path separator
    local path_str = table.concat(python_path, ";")

    -- Set PYTHONPATH environment variable
    vim.env.PYTHONPATH = path_str
    -- print "Set PYTHONPATH for tcloud-monitors-api project"
    vim.notify "Set PYTHONPATH for tcloud-monitors-api project"
  else
    --[[ print "Not in a known project directory" ]]
    vim.notify "Not in a known project directory"
  end
end

-- Function to setup the module and create autocmds
function M.setup()
  -- Create an autocommand to run this function when entering a directory
  vim.api.nvim_create_autocmd({ "DirChanged" }, {
    pattern = { "*" },
    callback = M.set_python_path,
  })

  -- Also run it once when Neovim starts
  M.set_python_path()
end

-- Return the module
return M
