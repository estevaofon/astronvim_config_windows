-- lua/utils/base64.lua
local M = {}

-- Base64 character set
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Decode base64 string
function M.decode(data)
  data = string.gsub(data, "[^" .. b .. "=]", "")
  return (
    data
      :gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (string.find(b, x, 1, true) or 0) - 1
        for i = 6, 1, -1 do
          r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
      end)
      :gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
          c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
      end)
  )
end

-- Encode string to base64
function M.encode(data)
  return (
    (data:gsub(".", function(x)
      local r, byte = "", x:byte()
      for i = 8, 1, -1 do
        r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
      end
      return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
      if #x < 6 then return "" end
      local c = 0
      for i = 1, 6 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
      end
      return b:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1]
  )
end

-- Function to decode visual selection
function M.decode_visual_selection()
  -- Get position of visual selection start and end
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  local lines = vim.fn.getline(start_line, end_line)
  if #lines == 0 then return end

  -- Adjust first and last line according to selection
  lines[1] = string.sub(lines[1], start_col)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)
  local selection = table.concat(lines, "\n")

  -- Decode base64 string
  local decoded = M.decode(selection)

  -- Create a new buffer (not listed and temporary)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(decoded, "\n"))

  -- Set floating window dimensions (80% of screen)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Window settings (minimal style with rounded border)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
  vim.api.nvim_open_win(buf, true, opts)
end

-- Function to encode visual selection
function M.encode_visual_selection()
  -- Get position of visual selection start and end
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  local lines = vim.fn.getline(start_line, end_line)
  if #lines == 0 then return end

  -- Adjust first and last line according to selection
  lines[1] = string.sub(lines[1], start_col)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)
  local selection = table.concat(lines, "\n")

  -- Encode selection to base64
  local encoded = M.encode(selection)

  -- Create temporary buffer (not listed)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(encoded, "\n"))

  -- Set dimensions and position of floating window (80% of screen)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }

  -- Open floating window with created buffer
  vim.api.nvim_open_win(buf, true, opts)
end

-- Setup function to define keymaps
function M.setup()
  -- Shortcut mapping for functions in visual mode (example: <leader>bd and <leader>be)
  vim.api.nvim_set_keymap(
    "v",
    "<leader>bd",
    ":lua require('utils.base64').decode_visual_selection()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap(
    "v",
    "<leader>be",
    ":lua require('utils.base64').encode_visual_selection()<CR>",
    { noremap = true, silent = true }
  )
end

return M
