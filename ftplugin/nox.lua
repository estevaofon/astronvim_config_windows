-- ftplugin/nox.lua - Configuração automática para arquivos .nx (linguagem Nox)
-- Este arquivo é executado automaticamente quando o filetype é definido como 'nox'

-- Verificar se o módulo nox está disponível
local has_nox, nox = pcall(require, "utils.nox")
if not has_nox then
  vim.notify("Módulo utils.nox não encontrado", vim.log.levels.ERROR)
  return
end

-- Configurar opções do buffer
vim.bo.commentstring = "// %s"
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

-- Aplicar highlighting
local buf = vim.api.nvim_get_current_buf()

-- Aplicar highlighting com pequeno delay para garantir que o buffer está pronto
vim.defer_fn(function()
  if vim.api.nvim_buf_is_valid(buf) then
    nox.attach(buf)
  end
end, 10)
