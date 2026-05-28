-- Customize resession (gerenciador de sessão do AstroNvim).
-- Exclui buffers de TERMINAL da sessão: quando um terminal fecha (ex.: o markterm do preview de
-- Markdown), sobra um buffer morto com nome `term://...` que, ao restaurar, dá E303 ("impossível
-- abrir arquivo de troca", nome de swap inválido). Mantém o filtro padrão do AstroNvim
-- (`is_restorable`) para o resto.
---@type LazySpec
return {
  "stevearc/resession.nvim",
  opts = function(_, opts)
    opts.buf_filter = function(bufnr)
      if vim.bo[bufnr].buftype == "terminal" or vim.api.nvim_buf_get_name(bufnr):find "^term://" then
        return false
      end
      return require("astrocore.buffer").is_restorable(bufnr)
    end
    return opts
  end,
}
