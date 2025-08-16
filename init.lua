-- Detect if running on Windows and set a platform-specific path separator
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local path_sep = is_windows and "\\" or "/"

-- vim.o.background = "light"
-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- BE CAUTIOUS editing this file and proceed at your own risk.

local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. path_sep .. "lazy" .. path_sep .. "lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Validate that lazy is available
if not pcall(require, "lazy") then
  vim.api.nvim_echo({
    { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" },
    { "Press any key to exit...", "MoreMsg" },
  }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

-- vim.cmd.colorscheme "solarized"
vim.cmd.colorscheme "catppuccin-mocha"
-- vim.cmd.colorscheme "tokyonight-night"

-- Define a global config variable
_G.my_pylsp_config = {
  pylsp = {
    plugins = {
      pycodestyle = { ignore = { "E501", "E126", "E127", "W391", "W504" } },
      pyflakes = { enabled = true }, -- initial state
    },
  },
}

local lspconfig = require "lspconfig"
lspconfig.pylsp.setup {
  settings = _G.my_pylsp_config,
}

-- require("persistent-breakpoints").setup {
--   load_breakpoints_event = { "BufReadPost" },
-- }

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
-- Save breakpoints to file automatically.
-- Delete F9 keymap to avoid conflicts with persistent-breakpoints.
vim.keymap.del("n", "<F9>")
-- keymap("n", "<F9>", "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>", opts)
vim.keymap.set(
  "n",
  "<F9>",
  function() require("dap").toggle_breakpoint() end,
  { noremap = true, silent = true, desc = "Toggle breakpoint" }
)

vim.keymap.set("n", "<F3>", ":bn<CR>", { desc = "Next Breakpoint" })
vim.keymap.set("n", "<F12>", require("dap").step_into, { desc = "Step Into Function" })
-- Step out
vim.keymap.set("n", "<F2>", require("dap").step_out, { desc = "Step Out of Function" })
vim.keymap.set("n", "<F6>", require("dap").terminate, { desc = "Stop Debugging" })

vim.api.nvim_set_keymap("n", "<leader>bd", ":lua safe_bdelete()<CR>", { noremap = true, silent = true })

-- Disable the default Tab mapping for Copilot and remap its accept action.
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-l>", "copilot#Accept('<CR>')", { expr = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>a", ":lua print(vim.fn.expand('%:p'))<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gp", ":GitSigns preview_hunk<CR>", {})

-- Use the environment variable HOME if available; otherwise, use USERPROFILE (common on Windows)

vim.api.nvim_set_keymap("n", "<C-a>", "ggVG", { noremap = true, silent = true })

vim.keymap.set("n", "<F4>", require("dap.ui.widgets").hover, { silent = true })

vim.keymap.set(
  "n",
  "<leader>cn",
  function() require("notify").dismiss { silent = true, pending = true } end,
  { desc = "Dismiss all notifications" }
)

vim.keymap.del("n", "<C-q>")
vim.api.nvim_set_keymap("n", "<C-q>", "<C-v>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })

-- In your init.lua, add this line where you want to set up the base64 functionality
require("utils.base64").setup()
require("utils.search").setup()
require("utils.json_utils").setup()
require("utils.python_path").setup()
require("utils.debugger").setup()
require("utils.my_utils").setup()
require("utils.markdown-preview").setup()

require("ailite").setup {
  assistant_name = "AiLite",
  assistant_prefix = "AiLite: ",
  max_tokens = 8192,
  context = {
    max_tokens_per_message = 6000, -- ajuste o valor conforme necessário
  },
}

-- Configuração do módulo nox.lua
-- O setup agora é simples - o highlighting real acontece via ftplugin/nox.lua
require("utils.nox").setup()

-- Opção 2: Se quiser configuração inline (copie o módulo aqui)
-- local nox = {}
-- [... código do módulo ...]
-- nox.setup()

-- Opção 3: Com lazy.nvim
-- {
--     dir = "~/.config/nvim/lua",
--     name = "nox-syntax",
--     config = function()
--         require('nox').setup()
--     end,
--     ft = "nox"
-- }

-- Comando útil para testar - agora o highlighting deve ser automático
vim.api.nvim_create_user_command("NoxTest", function()
  -- Ativar debug temporariamente
  local old_debug = vim.g.nox_debug
  vim.g.nox_debug = true
  
  -- Criar um buffer de teste
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)

  -- Código de exemplo
  local test_code = {
    "// HashMap (string -> int) com encadeamento separado",
    "struct EntryS",
    "    key: string,",
    "    value: int,",
    "    next: ref EntryS",
    "end",
    "",
    "let CAPACITY: int = 16",
    "let buckets: EntryS[16] = [null, null, null, null]",
    "",
    "func hash_str(s: string) -> int",
    "    let h: int = 5381",
    "    let i: int = 0",
    "    while i < strlen(s) do",
    "        let c: int = ord(s[i])",
    "        h = h * 33 + c",
    "        i = i + 1",
    "    end",
    "    if h < 0 then",
    "        h = 0 - h",
    "    end",
    "    return h % CAPACITY",
    "end",
    "",
    "func get_s(key: string) -> int",
    "    let idx: int = hash_str(key)",
    "    let cur: ref EntryS = buckets[idx]",
    "    while cur != null do",
    "        if str_eq(cur.key, key) then",
    "            return cur.value",
    "        end",
    "        cur = cur.next",
    "    end",
    "    return -1",
    "end",
    "",
    "// Demonstração",
    'print("HashMap demo:")',
    'put_s("one", 1)',
    'print(to_str(get_s("one")))',
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, test_code)
  
  print("Definindo filetype como 'nox' para buffer " .. buf)
  
  -- Definir o tipo de arquivo (isso deve ativar automaticamente o highlighting)
  vim.bo[buf].filetype = "nox"
  
  -- Aguardar um pouco e verificar se funcionou
  vim.defer_fn(function()
    local success, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "NoxHighlight_" .. buf })
    if success and autocmds and #autocmds > 0 then
      print("✓ Highlighting automático funcionando!")
    else
      print("✗ Highlighting automático falhou, aplicando manualmente...")
      require("utils.nox").attach(buf)
    end
    
    -- Restaurar debug
    vim.g.nox_debug = old_debug
  end, 100)

  print "Buffer de teste Nox criado!"
end, {})

-- Comando para debug do nox
vim.api.nvim_create_user_command("NoxDebug", function()
  vim.g.nox_debug = not vim.g.nox_debug
  print("Nox debug: " .. (vim.g.nox_debug and "ON" or "OFF"))
end, {})

-- Comando para criar um arquivo .nx real para teste
vim.api.nvim_create_user_command("NoxFile", function()
  local filename = "test_" .. os.time() .. ".nx"
  local test_code = [[// Arquivo de teste Nox
struct Person
    name: string,
    age: int
end

func greet(p: ref Person) -> void
    print("Hello, " + p.name)
    print("You are " + to_str(p.age) + " years old")
end

let person: Person = {name: "João", age: 25}
greet(person)]]

  -- Criar o arquivo
  local file = io.open(filename, "w")
  if file then
    file:write(test_code)
    file:close()
    vim.cmd("edit " .. filename)
    
    print("Arquivo " .. filename .. " criado e aberto!")
  else
    print("Erro ao criar arquivo!")
  end
end, {})

-- Comando para verificar status do nox
vim.api.nvim_create_user_command("NoxStatus", function()
  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo.filetype
  
  print("=== Status do Nox ===")
  print("Buffer: " .. buf)
  print("Arquivo: " .. filename)
  print("Filetype: '" .. ft .. "'")
  print("É arquivo .nx: " .. (filename:match("%.nx$") and "SIM" or "NÃO"))
  
  -- Verificar se highlighting está aplicado
  local success, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "NoxHighlight_" .. buf })
  print("Highlighting aplicado: " .. ((success and autocmds and #autocmds > 0) and "SIM" or "NÃO"))
  
  -- Forçar filetype se necessário
  if filename:match("%.nx$") and ft ~= "nox" then
    print("Definindo filetype como 'nox'...")
    vim.bo.filetype = "nox"
  end
end, {})
