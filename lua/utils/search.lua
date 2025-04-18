local M = {}

-- Function for search and replace
function M.search_replace_prompt()
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

-- Function for literal search
function M.literal_search_prompt()
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

function M.setup()
  -- Create a user command for literal search
  vim.api.nvim_create_user_command("LiteralSearch", M.literal_search_prompt, {})
  -- Create a user command for convenience
  -- Optionally, map a key (here <leader>ls) to invoke the prompt
  vim.api.nvim_set_keymap("n", "<leader>ls", ":LiteralSearch<CR>", { noremap = true, silent = true })

  vim.api.nvim_create_user_command("SearchReplace", M.search_replace_prompt, {})

  vim.keymap.set("n", "<leader>sr", M.search_replace_prompt, { desc = "Search and Replace" })
end

return M
