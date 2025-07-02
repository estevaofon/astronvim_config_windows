-- markdown-preview.lua

local api = vim.api
local fn = vim.fn

local M = {}

-- Função para converter Markdown em texto formatado com sintaxe
local function format_markdown_line(line)
  -- Headers com diferentes níveis e formatação
  line = line:gsub("^(#+)%s+(.+)", function(hashes, text)
    local level = #hashes
    local prefix = string.rep("#", level) .. " "
    if level == 1 then
      return prefix .. string.upper(text)
    elseif level == 2 then
      return prefix .. "『" .. text .. "』"
    else
      return prefix .. text
    end
  end)

  -- Code blocks inline
  line = line:gsub("`([^`]+)`", function(code) return "「" .. code .. "」" end)

  -- Bold (suporta tanto ** quanto __)
  line = line:gsub("%*%*(.-)%*%*", "𝗕%1𝗕")
  line = line:gsub("__(.-)__", "𝗕%1𝗕")

  -- Italic (suporta tanto * quanto _)
  line = line:gsub("%*([^%*_]+)%*", "𝘐%1𝘐")
  line = line:gsub("_([^%*_]+)_", "𝘐%1𝘐")

  -- Strike-through
  line = line:gsub("~~(.-)~~", "̶%1̶")

  -- Links
  line = line:gsub("%[(.-)%]%((.-)%)", function(text, url) return "🔗 " .. text .. " (" .. url .. ")" end)

  -- Lists não ordenadas (suporta -, + e *)
  line = line:gsub("^%s*[%-+%*]%s+(.+)", function(text) return "• " .. text end)

  -- Lists ordenadas
  line = line:gsub("^%s*(%d+)%.%s+(.+)", function(num, text) return num .. "➤ " .. text end)

  -- Blockquotes
  line = line:gsub("^%s*>%s+(.+)", function(text) return "┃ " .. text end)

  -- Horizontal rules
  line = line:gsub("^%-%-%-+$", "━━━━━━━━━━━━━━━━━━━━")
  line = line:gsub("^%*%*%*+$", "━━━━━━━━━━━━━━━━━━━━")
  line = line:gsub("^___+$", "━━━━━━━━━━━━━━━━━━━━")

  -- Task lists
  line = line:gsub("%[%s%]", "☐")
  line = line:gsub("%[x%]", "☑")
  line = line:gsub("%[X%]", "☑")

  return line
end

function M.preview_markdown()
  -- Salvar o buffer atual
  local current_buf = api.nvim_get_current_buf()

  -- Criar novo buffer para preview
  local preview_buf = api.nvim_create_buf(false, true)

  -- Configurar o buffer
  api.nvim_buf_set_option(preview_buf, "buftype", "nofile")
  api.nvim_buf_set_option(preview_buf, "swapfile", false)
  api.nvim_buf_set_option(preview_buf, "filetype", "markdown")
  api.nvim_buf_set_option(preview_buf, "modifiable", true)

  -- Criar janela dividida verticalmente
  vim.cmd "vsplit"
  local win = api.nvim_get_current_win()
  api.nvim_win_set_buf(win, preview_buf)

  -- Obter conteúdo do buffer original
  local lines = api.nvim_buf_get_lines(current_buf, 0, -1, false)

  -- Formatar e mostrar o conteúdo
  local formatted_lines = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(formatted_lines, format_markdown_line(line))
    else
      table.insert(formatted_lines, line) -- Preservar linhas em branco
    end
  end

  -- Definir as linhas no buffer de preview
  api.nvim_buf_set_lines(preview_buf, 0, -1, false, formatted_lines)

  -- Adicionar syntax highlighting
  vim.cmd [[
    highlight MarkdownHeader1 guifg=#ff5f5f gui=bold
    highlight MarkdownHeader2 guifg=#ff875f gui=bold
    highlight MarkdownHeader3 guifg=#ffaf5f gui=bold
    highlight MarkdownBold guifg=#ffffff gui=bold
    highlight MarkdownItalic guifg=#ffffff gui=italic
    highlight MarkdownList guifg=#87afff
    highlight MarkdownQuote guifg=#87875f gui=italic
    highlight MarkdownLink guifg=#5f87ff
    highlight MarkdownCode guifg=#5faf5f gui=none
    highlight MarkdownHRule guifg=#444444 gui=none
  ]]

  -- Aplicar highlights
  local ns_id = api.nvim_create_namespace "markdown_preview"
  for i, line in ipairs(formatted_lines) do
    if line:match "^#%s+" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownHeader1", i - 1, 0, -1)
    elseif line:match "^##%s+" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownHeader2", i - 1, 0, -1)
    elseif line:match "^###%s+" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownHeader3", i - 1, 0, -1)
    elseif line:match "^•%s+" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownList", i - 1, 0, -1)
    elseif line:match "^┃" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownQuote", i - 1, 0, -1)
    elseif line:match "^━━━" then
      api.nvim_buf_add_highlight(preview_buf, ns_id, "MarkdownHRule", i - 1, 0, -1)
    end
  end

  -- Configurar atualizações automáticas
  local augroup = vim.api.nvim_create_augroup("MarkdownPreviewUpdate", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    buffer = current_buf,
    callback = function() M.update_preview(preview_buf) end,
  })

  return preview_buf
end

function M.update_preview(preview_buf)
  if not api.nvim_buf_is_valid(preview_buf) then return end

  local current_buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(current_buf, 0, -1, false)

  local formatted_lines = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(formatted_lines, format_markdown_line(line))
    else
      table.insert(formatted_lines, line)
    end
  end

  api.nvim_buf_set_option(preview_buf, "modifiable", true)
  api.nvim_buf_set_lines(preview_buf, 0, -1, false, formatted_lines)
  api.nvim_buf_set_option(preview_buf, "modifiable", false)
end

function M.setup()
  vim.api.nvim_create_user_command("MarkdownPreview", function() M.preview_markdown() end, {})
end

return M
