-- ailite/keymaps.lua
-- Keymap configuration

local M = {}

-- Setup default keymaps
function M.setup()
  local chat = require "utils.ailite_module.chat"
  local files = require "utils.ailite_module.files"
  local code = require "utils.ailite_module.code"
  local context = require "utils.ailite_module.context"
  local api = require "utils.ailite_module.api"
  local ailite = require "utils.ailite_module"

  -- Define keymaps
  local keymaps = {
    { "n", "<leader>cc", chat.toggle_chat, "Toggle Ailite Chat" },
    { "n", "<leader>cp", ailite.prompt, "Ailite Quick Prompt" },
    { "v", "<leader>cp", ailite.prompt_with_selection, "Ailite Prompt with Selection" },
    { "n", "<leader>cf", files.select_files, "Ailite Select Files for Context" },
    { "n", "<leader>cl", files.list_selected_files, "Ailite List Selected Files" },
    { "n", "<leader>ct", files.toggle_current_file, "Ailite Toggle Current File" },
    { "n", "<leader>ci", ailite.show_info, "Show Ailite Info" },
    { "n", "<leader>ch", chat.show_help, "Show Ailite Help" },
    {
      "n",
      "<leader>ca",
      function()
        local state = require "utils.ailite_module.state"
        if #state.plugin.code_blocks > 0 then
          code.show_code_preview(1)
        else
          local utils = require "utils.ailite_module.utils"
          utils.notify("No code blocks available", vim.log.levels.WARN)
        end
      end,
      "Apply Code from Last Response",
    },
    { "n", "<leader>cr", code.replace_file_with_last_code, "Replace Entire File with Code" },
    { "n", "<leader>cd", code.apply_code_with_diff, "Apply Code with Diff Preview" },
    { "n", "<leader>ce", context.estimate_context, "Estimate Context Size" },
  }

  -- Create keymaps
  for _, map in ipairs(keymaps) do
    vim.keymap.set(map[1], map[2], map[3], { desc = map[4], noremap = true, silent = true })
  end

  -- Special handling for visual mode to preserve selection
  vim.keymap.set("x", "<leader>cp", ":<C-U>lua require('utils.ailite_module').prompt_with_selection()<CR>", {
    desc = "Ailite Prompt with Selection",
    noremap = true,
    silent = true,
  })
end

return M
