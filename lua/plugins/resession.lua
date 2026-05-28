-- Customize resession (gerenciador de sessão do AstroNvim).
-- Exclui da sessão qualquer buffer cujo nome seja uma URI `scheme://` (term://, health://,
-- fugitive://, etc.) e terminais. Motivo: quando um terminal/health fecha, sobra um buffer morto
-- com `buftype == ""` e nome `xxx://...` que passa pelo `is_restorable` do AstroNvim (ele só checa
-- nome quando buftype=="") e é salvo. Ao restaurar, o resession tenta abri-lo como ARQUIVO → erros
-- (E303 swap, statusline com bufnr inválido). O `%a[%w%+%-%.]*://` casa só URIs com `://` duplo,
-- então caminhos do Windows (`C:/...`, um único `/`) NÃO são afetados.
---@type LazySpec
return {
  "stevearc/resession.nvim",
  opts = function(_, opts)
    opts.buf_filter = function(bufnr)
      if vim.bo[bufnr].buftype == "terminal" then return false end
      if vim.api.nvim_buf_get_name(bufnr):find "^%a[%w%+%-%.]*://" then return false end
      return require("astrocore.buffer").is_restorable(bufnr)
    end
    return opts
  end,
}
