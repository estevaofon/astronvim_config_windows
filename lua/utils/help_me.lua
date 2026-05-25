-- utils.help_me.lua
-- Janela flutuante com a "cola" dos principais atalhos e comandos do dia a dia.
-- Abra com  :HelpMe  ou  <leader>?
-- Criado por Estevao Fonseca
local M = {}

-- Cada seção: { title = "...", items = { { "<tecla>", "descrição" }, ... } }
-- Mantenha aqui só o que você realmente usa no dia a dia.
local sections = {
  {
    title = "CAMINHOS  (copiar o path do arquivo)",
    items = {
      { "<leader>pa", "Copiar caminho ABSOLUTO" },
      { "<leader>pr", "Copiar caminho RELATIVO (à pasta do projeto)" },
      { "<leader>pn", "Copiar só o NOME do arquivo" },
      { "<leader>pd", "Copiar o DIRETÓRIO do arquivo" },
      { "<leader>pl", "Copiar caminho relativo + LINHA  (src\\app.py:42)" },
      { "<leader>a", "Mostrar caminho absoluto no echo (não copia)" },
    },
  },
  {
    title = "BUSCA (Telescope & no arquivo)",
    items = {
      { "<leader>ff", "Procurar ARQUIVO no projeto todo (find files)" },
      { "<leader>fw", "Procurar STRING no projeto todo (live grep)" },
      { "<leader>fg", "Live grep no projeto — seu alias (ou <leader>lg)" },
      { "<leader>fc", "Procurar a palavra sob o cursor no projeto" },
      { "<leader>ls", "Busca literal no arquivo, sem regex (:LiteralSearch)" },
      { "<leader>sr", "Buscar e substituir no arquivo (:SearchReplace)" },
      { "<C-a>", "Selecionar tudo (ggVG)" },
    },
  },
  {
    title = "ARQUIVOS & BUFFERS",
    items = {
      { "]b", "Próximo buffer" },
      { "[b", "Buffer anterior" },
      { "<F3>", "Próximo buffer (:bn)" },
      { "<leader>bd", "Fechar buffer atual" },
      { "<leader>ba", "Fechar todos os buffers e alternar Neotree" },
    },
  },
  {
    title = "CÓDIGO (LSP & Git)",
    items = {
      { "gd", "Ir para a definição" },
      { "gD", "Ir para a declaração" },
      { "<leader>gp", "Preview do hunk do Git (GitSigns)" },
      { "<C-l> / <C-d>", "Aceitar sugestão do Copilot (modo insert)" },
    },
  },
  {
    title = "DEBUG (DAP)",
    items = {
      { "<F9>", "Toggle breakpoint" },
      { "<F12>", "Step into" },
      { "<F2>", "Step out" },
      { "<F6>", "Parar o debug" },
      { "<F4>", "Hover: valor sob o cursor" },
      { "<F1>", "Avaliar expressão (dapui)" },
      { "<F8>", "Copiar valor da variável p/ novo buffer" },
      { "<leader>cb", "Limpar todos os breakpoints (:ClearBreakpoints)" },
      { "<leader>dq", "Voltar ao arquivo onde o debug começou" },
    },
  },
  {
    title = "TEXTO & UTILITÁRIOS",
    items = {
      { "<leader>is", "Inverter as barras da linha  (/ -> \\)" },
      { "<leader>w", "Inserir snippet de Lambda handler" },
      { "<leader>cn", "Limpar todas as notificações" },
      { "<C-q>", "Seleção visual em BLOCO (Ctrl-V)" },
      { "<leader>be", "(visual) Codificar seleção em Base64" },
      { "<leader>bd", "(visual) Decodificar seleção Base64" },
      { "<leader>p", "(visual) Formatar JSON / dict Python" },
    },
  },
  {
    title = "COMANDOS  ( : )",
    items = {
      { ":HelpMe", "Abrir esta ajuda" },
      { ":TogglePyflakes", "Liga/desliga o linter pyflakes" },
      { ":ClearBreakpoints", "Limpar todos os breakpoints" },
      { ":LiteralSearch", "Busca literal (sem regex)" },
      { ":SearchReplace", "Buscar e substituir no arquivo" },
      { ":InsertLambdaSnippet", "Inserir snippet de Lambda" },
      { ":MarkdownPreview", "Pré-visualizar Markdown" },
      { ":NoxHighlight / :NoxRefresh", "Realce da linguagem Nox" },
    },
  },
}

-- Monta as linhas do buffer e a lista de realces { line, col_start, col_end, group }.
local function build()
  local lines, hl = {}, {}
  local function push(text)
    table.insert(lines, text)
    return #lines - 1 -- índice 0-based da linha recém-adicionada
  end
  local function mark(line, cs, ce, group) table.insert(hl, { line = line, col_start = cs, col_end = ce, group = group }) end

  push ""
  local title = "  Atalhos & Comandos do dia a dia"
  mark(push(title), 0, #title, "HelpMeTitle")
  push ""

  for _, s in ipairs(sections) do
    -- alinha as teclas pela maior tecla DENTRO da seção
    local keyw = 0
    for _, it in ipairs(s.items) do
      keyw = math.max(keyw, #it[1])
    end

    local htext = "  " .. s.title
    mark(push(htext), 0, #htext, "HelpMeHeader")
    push ""
    for _, it in ipairs(s.items) do
      local key, desc = it[1], it[2]
      local indent = "    "
      local line = indent .. key .. string.rep(" ", keyw - #key) .. "   " .. desc
      mark(push(line), #indent, #indent + #key, "HelpMeKey")
    end
    push ""
  end

  local sep = "  " .. string.rep("─", 52)
  mark(push(sep), 0, #sep, "HelpMeHint")
  local hint = "  q / <Esc> fechar   ·   / buscar   ·   j / k rolar"
  mark(push(hint), 0, #hint, "HelpMeHint")
  local credit = "  criado por Estevao Fonseca"
  mark(push(credit), 0, #credit, "HelpMeTitle")
  push ""

  return lines, hl
end

local function open_float(lines, hl)
  local buf = vim.api.nvim_create_buf(false, true) -- scratch, sem arquivo
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace "help_me"
  for _, h in ipairs(hl) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.col_start, {
      end_row = h.line,
      end_col = h.col_end,
      hl_group = h.group,
    })
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "help_me"

  -- dimensões a partir do conteúdo (respeitando o tamanho da tela)
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 4, math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.85))
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Help Me · Neovim ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, opts)
end

-- Abre a janela de ajuda.
function M.show()
  -- (re)define os grupos de realce ligados ao colorscheme atual
  vim.api.nvim_set_hl(0, "HelpMeTitle", { link = "Title" })
  vim.api.nvim_set_hl(0, "HelpMeHeader", { link = "Function" })
  vim.api.nvim_set_hl(0, "HelpMeKey", { link = "String" })
  vim.api.nvim_set_hl(0, "HelpMeHint", { link = "Comment" })

  local lines, hl = build()
  open_float(lines, hl)
end

function M.setup()
  vim.api.nvim_create_user_command("HelpMe", M.show, { desc = "Mostra a cola de atalhos e comandos" })
  vim.keymap.set("n", "<leader>?", M.show, { noremap = true, silent = true, desc = "Help Me (cola de atalhos)" })
end

return M
