-- markdown-preview.lua
-- Preview de Markdown renderizando com `markterm.exe` num split de terminal.
-- markterm produz saída ANSI/truecolor (código, imagens, diagramas Mermaid),
-- então usamos um buffer :terminal, que interpreta os escapes e rola sozinho.

local api = vim.api
local fn = vim.fn

local M = {}

-- Executável instalado pelo `uv tool install` (em ~/.local/bin, no PATH).
local EXE = "markterm.exe"

-- Estado do preview ativo, para o re-render ao salvar.
local state = { win = nil, group = nil }

-- Monta o comando de render para um caminho absoluto.
local function render_cmd(file) return string.format("%s %s", EXE, fn.shellescape(file)) end

-- Descobre o arquivo a renderizar a partir do buffer.
-- Buffers nomeados são salvos (se modificados) para manter o disco em dia e
-- preservar caminhos relativos (imagens etc.); buffers sem nome vão para um
-- arquivo temporário.
local function source_file(buf)
  local name = api.nvim_buf_get_name(buf)
  if name ~= "" and vim.bo[buf].buftype == "" then
    if vim.bo[buf].modified then vim.cmd "silent! update" end
    return name
  end
  local tmp = fn.tempname() .. ".md"
  fn.writefile(api.nvim_buf_get_lines(buf, 0, -1, false), tmp)
  return tmp
end

-- (Re)cria um terminal markterm em `win`, descartando o buffer anterior.
local function render_into(win, file)
  if not api.nvim_win_is_valid(win) then return end
  local prev = api.nvim_win_get_buf(win)

  api.nvim_set_current_win(win)
  vim.cmd("terminal " .. render_cmd(file))
  local buf = api.nvim_get_current_buf()

  -- Remove o buffer de terminal anterior para não acumular órfãos.
  if prev ~= buf and api.nvim_buf_is_valid(prev) and vim.bo[prev].buftype == "terminal" then
    pcall(api.nvim_buf_delete, prev, { force = true })
  end

  -- Painel limpo, sem números/sinais/spell.
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].spell = false

  -- `q` fecha o preview.
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
end

function M.preview_markdown()
  local src_buf = api.nvim_get_current_buf()
  local src_win = api.nvim_get_current_win()
  local file = source_file(src_buf)

  -- Split à direita com o preview; o foco volta para o arquivo de origem.
  vim.cmd "botright vsplit"
  local win = api.nvim_get_current_win()
  render_into(win, file)
  if api.nvim_win_is_valid(src_win) then api.nvim_set_current_win(src_win) end

  -- Re-render ao salvar, enquanto o painel de preview existir
  -- (equivalente sano ao "live update" da versão anterior).
  if state.group then pcall(api.nvim_del_augroup_by_id, state.group) end
  state.win = win
  state.group = api.nvim_create_augroup("MarkdownPreviewUpdate", { clear = true })
  api.nvim_create_autocmd("BufWritePost", {
    group = state.group,
    buffer = src_buf,
    callback = function()
      if not api.nvim_win_is_valid(state.win) then
        pcall(api.nvim_del_augroup_by_id, state.group)
        state.group = nil
        return
      end
      local cur = api.nvim_get_current_win()
      render_into(state.win, source_file(src_buf))
      if api.nvim_win_is_valid(cur) then api.nvim_set_current_win(cur) end
    end,
  })
end

function M.setup()
  api.nvim_create_user_command(
    "MarkdownPreview",
    function() M.preview_markdown() end,
    { desc = "Preview de Markdown com markterm" }
  )
  vim.keymap.set(
    "n",
    "<leader>mp",
    M.preview_markdown,
    { noremap = true, silent = true, desc = "Preview de Markdown (markterm)" }
  )
end

return M
