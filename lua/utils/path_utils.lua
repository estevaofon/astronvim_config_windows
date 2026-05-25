-- utils.path_utils.lua
-- Atalhos para copiar o caminho do arquivo atual (absoluto, relativo, nome, etc.)
-- Grupo de teclas: <leader>p  (modo normal)
-- Criado por Estevao Fonseca
local M = {}

-- Copia `value` para o clipboard do sistema (+) e para o registrador sem-nome (")
-- e notifica mostrando o que foi copiado. Avisa caso o buffer não seja um arquivo.
local function copy(value, label)
  if value == nil or value == "" then
    vim.notify("path_utils: o buffer atual não tem um arquivo no disco.", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", value) -- clipboard do sistema (Ctrl+V fora do nvim)
  vim.fn.setreg('"', value) -- registrador sem-nome (cola com `p` dentro do nvim)
  vim.notify(string.format("%s copiado:\n%s", label, value), vim.log.levels.INFO)
end

-- Caminho absoluto:  D:\...\projeto\src\arquivo.py
function M.copy_absolute() copy(vim.fn.expand "%:p", "Caminho absoluto") end

-- Caminho relativo à pasta de trabalho (cwd):  src\arquivo.py
function M.copy_relative() copy(vim.fn.expand "%:.", "Caminho relativo") end

-- Apenas o nome do arquivo:  arquivo.py
function M.copy_filename() copy(vim.fn.expand "%:t", "Nome do arquivo") end

-- Diretório (absoluto) que contém o arquivo
function M.copy_dir() copy(vim.fn.expand "%:p:h", "Diretório") end

-- Caminho relativo + número da linha atual:  src\arquivo.py:42
function M.copy_relative_with_line()
  local rel = vim.fn.expand "%:."
  if rel == "" then
    copy("", "Caminho relativo + linha")
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  copy(string.format("%s:%d", rel, line), "Caminho relativo + linha")
end

function M.setup()
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { noremap = true, silent = true, desc = desc })
  end

  map("<leader>pa", M.copy_absolute, "Copiar caminho absoluto")
  map("<leader>pr", M.copy_relative, "Copiar caminho relativo")
  map("<leader>pn", M.copy_filename, "Copiar nome do arquivo")
  map("<leader>pd", M.copy_dir, "Copiar diretório do arquivo")
  map("<leader>pl", M.copy_relative_with_line, "Copiar caminho relativo + linha")

  -- Comandos equivalentes (úteis em scripts ou quando se esquece o atalho)
  vim.api.nvim_create_user_command("CopyAbsolutePath", M.copy_absolute, { desc = "Copiar caminho absoluto" })
  vim.api.nvim_create_user_command("CopyRelativePath", M.copy_relative, { desc = "Copiar caminho relativo" })
end

return M
