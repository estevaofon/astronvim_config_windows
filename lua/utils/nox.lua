-- nox.lua - Syntax highlighting para linguagem Nox no Neovim
local M = {}

-- Namespace para highlights
local ns_id = vim.api.nvim_create_namespace "nox_highlight"

-- Definir grupos de highlight
function M.setup_highlights()
  vim.api.nvim_set_hl(0, "NoxKeyword", { fg = "#ff0080", bold = true })
  vim.api.nvim_set_hl(0, "NoxType", { fg = "#64c8ff" })
  vim.api.nvim_set_hl(0, "NoxString", { fg = "#00ffff" })
  vim.api.nvim_set_hl(0, "NoxNumber", { fg = "#ffd700" })
  vim.api.nvim_set_hl(0, "NoxComment", { fg = "#808080", italic = true })
  vim.api.nvim_set_hl(0, "NoxOperator", { fg = "#ff64ff" })
  vim.api.nvim_set_hl(0, "NoxBoolean", { fg = "#ffa500" })
  vim.api.nvim_set_hl(0, "NoxNull", { fg = "#9370db" })
  vim.api.nvim_set_hl(0, "NoxBuiltin", { fg = "#32cd32" })
  vim.api.nvim_set_hl(0, "NoxFunction", { fg = "#00ff80" })
  vim.api.nvim_set_hl(0, "NoxIdentifier", { fg = "#ffffff" })
  vim.api.nvim_set_hl(0, "NoxDelimiter", { fg = "#888888" })
end

-- Palavras-chave e tipos
local keywords = {
  ["struct"] = true,
  ["end"] = true,
  ["let"] = true,
  ["func"] = true,
  ["return"] = true,
  ["if"] = true,
  ["then"] = true,
  ["else"] = true,
  ["while"] = true,
  ["do"] = true,
  ["for"] = true,
  ["in"] = true,
  ["ref"] = true,
  ["void"] = true,
}

local types = {
  ["int"] = true,
  ["string"] = true,
  ["bool"] = true,
  ["void"] = true,
}

local builtins = {
  ["print"] = true,
  ["strlen"] = true,
  ["ord"] = true,
  ["to_str"] = true,
}

local booleans = {
  ["true"] = true,
  ["false"] = true,
}

local nulls = {
  ["null"] = true,
}

-- Padrões de match
local patterns = {
  -- Comentário tem que vir primeiro
  { pattern = "//.*$", hl = "NoxComment" },
  -- Strings
  { pattern = '"[^"]*"', hl = "NoxString" },
  { pattern = "'[^']*'", hl = "NoxString" },
  -- Números (incluindo negativos)
  { pattern = "%-?%d+%.?%d*", hl = "NoxNumber" },
  -- Operadores de 2 caracteres
  { pattern = "==", hl = "NoxOperator" },
  { pattern = "!=", hl = "NoxOperator" },
  { pattern = "<=", hl = "NoxOperator" },
  { pattern = ">=", hl = "NoxOperator" },
  { pattern = "%->", hl = "NoxOperator" },
  { pattern = "%.%.", hl = "NoxOperator" },
  -- Operadores de 1 caractere
  { pattern = "[%+%-%*/%%=<>!]", hl = "NoxOperator" },
  -- Delimitadores
  { pattern = "[%(%)]", hl = "NoxDelimiter" },
  { pattern = "[%[%]]", hl = "NoxDelimiter" },
  { pattern = "[{}]", hl = "NoxDelimiter" },
  { pattern = "[,;:]", hl = "NoxDelimiter" },
  { pattern = "%.", hl = "NoxDelimiter" },
  -- Identificadores (palavras)
  { pattern = "[%a_][%w_]*", hl = "word" },
}

-- Função para aplicar highlights em uma linha
function M.highlight_line(bufnr, line_num, line_content)
  -- Limpar highlights anteriores nesta linha
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_num, line_num + 1)

  local col = 0
  local remaining = line_content

  while #remaining > 0 do
    local matched = false

    -- Tentar cada padrão
    for _, p in ipairs(patterns) do
      local start_pos, end_pos = string.find(remaining, "^" .. p.pattern)

      if start_pos then
        local matched_text = string.sub(remaining, start_pos, end_pos)
        local hl_group = p.hl

        -- Se for uma palavra, verificar se é keyword, type, etc
        if p.hl == "word" then
          if keywords[matched_text] then
            hl_group = "NoxKeyword"
          elseif types[matched_text] then
            hl_group = "NoxType"
          elseif builtins[matched_text] then
            hl_group = "NoxBuiltin"
          elseif booleans[matched_text] then
            hl_group = "NoxBoolean"
          elseif nulls[matched_text] then
            hl_group = "NoxNull"
          else
            -- Verificar se é uma função (seguido de '(')
            local next_char = string.sub(remaining, end_pos + 1, end_pos + 1)
            local has_space = string.match(string.sub(remaining, end_pos + 1), "^%s*%(")
            if next_char == "(" or has_space then
              hl_group = "NoxFunction"
            else
              hl_group = "NoxIdentifier"
            end
          end
        end

        -- Aplicar highlight
        if hl_group ~= "NoxIdentifier" then -- Não destacar identificadores normais
          vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, line_num, col, col + #matched_text)
        end

        col = col + #matched_text
        remaining = string.sub(remaining, end_pos + 1)
        matched = true
        break
      end
    end

    -- Se não encontrou nenhum padrão, avançar um caractere
    if not matched then
      col = col + 1
      remaining = string.sub(remaining, 2)
    end
  end
end

-- Função para destacar todo o buffer
function M.highlight_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    M.highlight_line(bufnr, i - 1, line)
  end
end

-- Função para anexar a um buffer
function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Verificar se já está anexado para evitar duplicação
  local group_name = "NoxHighlight_" .. bufnr
  local success, autocmds = pcall(vim.api.nvim_get_autocmds, { group = group_name, buffer = bufnr })
  if success and autocmds and #autocmds > 0 then
    return -- Já está anexado
  end

  -- Aplicar highlight inicial
  M.highlight_buffer(bufnr)

  -- Criar autocmd para atualizar ao editar
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter", "InsertLeave" }, {
    buffer = bufnr,
    callback = function() 
      -- Verificar se o buffer ainda é válido
      if vim.api.nvim_buf_is_valid(bufnr) then
        M.highlight_buffer(bufnr) 
      end
    end,
    group = vim.api.nvim_create_augroup(group_name, { clear = true }),
  })

  -- Debug: mostrar que foi anexado
  if vim.g.nox_debug then
    print("Nox highlighting attached to buffer " .. bufnr)
  end
end

-- Setup principal
function M.setup()
  -- Configurar highlights
  M.setup_highlights()

  -- Registrar tipo de arquivo
  vim.filetype.add {
    extension = {
      nx = "nox",  -- arquivos .nx usam filetype 'nox'
    },
    pattern = {
      [".*%.nx$"] = "nox",
    },
  }

  -- Comandos úteis
  vim.api.nvim_create_user_command("NoxHighlight", function()
    M.highlight_buffer()
  end, { desc = "Force Nox syntax highlighting" })

  vim.api.nvim_create_user_command("NoxRefresh", function()
    local count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local filename = vim.api.nvim_buf_get_name(buf)
        local is_nox = filename:match("%.nx$") or vim.bo[buf].filetype == "nox"
        
        if is_nox then
          vim.bo[buf].filetype = "nox"
          M.attach(buf)
          count = count + 1
        end
      end
    end
    print("Nox highlighting aplicado a " .. count .. " buffer(s)")
  end, { desc = "Refresh Nox highlighting for all .nox buffers" })


end

return M

