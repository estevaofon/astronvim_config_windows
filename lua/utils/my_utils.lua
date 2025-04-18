-- utils.lua
local M = {}

function M.close_all_buffers()
  vim.cmd "silent! %bdelete"
  vim.cmd "Neotree toggle"
end

-- Initialize module
function M.setup()
  -- Create a command to toggle pyflakes and restart the server
  vim.api.nvim_create_user_command("TogglePyflakes", function()
    -- Toggle the pyflakes setting in the global config
    _G.my_pylsp_config.pylsp.plugins.pyflakes.enabled = not _G.my_pylsp_config.pylsp.plugins.pyflakes.enabled
    print("Pyflakes is now " .. (_G.my_pylsp_config.pylsp.plugins.pyflakes.enabled and "enabled" or "disabled"))
    -- Restart the server so it picks up the updated config
    vim.cmd "LspRestart"
  end, {})

  -- Create Lambda snippet command
  vim.api.nvim_create_user_command("InsertLambdaSnippet", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, {
      'if __name__ == "__main__":',
      "    event = {}",
      "    lambda_handler(event, context=None)",
    })
  end, {})

  -- Set up key mappings
  vim.api.nvim_set_keymap("n", "<leader>w", ":InsertLambdaSnippet<CR>", { noremap = true, silent = true })

  -- Configure shell for Windows
  if vim.loop.os_uname().sysname == "Windows_NT" then
    vim.opt.shell = "powershell"
    vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
    vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
  end

  -- Set up Telescope
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
  -- Telescope keymaps
  vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("n", "<leader>lg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
  -- Copilot keymap
  vim.api.nvim_set_keymap("i", "<C-d>", "copilot#Accept('<CR>')", { expr = true, silent = true })
  -- DAP breakpoint management
  vim.api.nvim_set_keymap(
    "n",
    "<Leader>cb",
    ":lua require('utils').clear_all_breakpoints()<CR>",
    { noremap = true, silent = true }
  )
  -- Create a command to run the breakpoint clearing function
  vim.cmd "command! ClearBreakpoints lua require('utils').clear_all_breakpoints()"
  -- Slash inversion keymap
  vim.api.nvim_set_keymap(
    "n",
    "<leader>is",
    "<cmd>lua require('utils').invert_slashes()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap(
    "n",
    "<leader>ba",
    ":lua require('utils').close_all_buffers()<CR>",
    { noremap = true, silent = true }
  )

  require("toggleterm").setup {
    direction = "vertical", -- this makes the terminal open vertically
    size = 80, -- adjust the width as needed
  }
end

-- Define a function to clear all breakpoints using nvim-dap
function M.clear_all_breakpoints()
  require("dap").clear_breakpoints()
  print "All breakpoints cleared!"
end

-- Function to invert slashes in the current line
function M.invert_slashes()
  local line = vim.api.nvim_get_current_line()
  -- Replace all occurrences of "/" with "\"
  local new_line = line:gsub("/", "\\")
  vim.api.nvim_set_current_line(new_line)
end

return M
