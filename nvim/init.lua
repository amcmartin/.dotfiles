-- Leader
vim.g.mapleader = " "

-- Basic UI
vim.opt.number = true
vim.opt.relativenumber = true

-- jj to exit insert; mode-aware cursor
vim.keymap.set("i", "jj", "<Esc>")
vim.cmd([[
  let &t_SI = "\e[6 q"  " thin bar in insert
  let &t_EI = "\e[2 q"  " block in normal/visual
]])

-- lazy.nvim bootstrap (skip if you already have this)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({"git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git","--branch=stable", lazypath})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "j-hui/fidget.nvim", opts = {} },        -- nice LSP status
  -- Telescope fuzzy finder
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", tag = "0.1.6", dependencies = { "nvim-lua/plenary.nvim" } },
  -- Completion stack
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },
})

-- nvim-cmp setup
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = {
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "path" },
    { name = "buffer" },
    { name = "luasnip" },
  },
})

-- LSP setup
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Ensure servers installed via mason
-- Ensure servers installed via mason (prefer ts_ls; fall back to tsserver)
local ensure = { "basedpyright", "ruff" }
if lspconfig.ts_ls then
  table.insert(ensure, "ts_ls")
elseif lspconfig.tsserver and type(lspconfig.tsserver.setup) == "function" then
  table.insert(ensure, "tsserver")
end
require("mason-lspconfig").setup({
  ensure_installed = ensure,
  automatic_installation = true,
})

-- basedpyright (type checker / language server)
lspconfig.basedpyright.setup({
  capabilities = capabilities,
  settings = {
    basedpyright = {
      analysis = {
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
        typeCheckingMode = "standard", -- "standard" or "strict"
      },
      -- If you keep a .venv in project root, pyright finds it automatically.
      -- Otherwise, you can add a pyrightconfig.json with venvPath/venv.
    },
  },
})

-- ruff (lint + format via LSP)
lspconfig.ruff.setup({
  capabilities = capabilities,
  init_options = { settings = { args = {} } }, -- customize ruff args if needed
})

-- TypeScript / JavaScript (prefer ts_ls; fallback tsserver when setup available)
local ts_server_name = nil
if lspconfig.ts_ls then
  ts_server_name = "ts_ls"
elseif lspconfig.tsserver and type(lspconfig.tsserver.setup) == "function" then
  ts_server_name = "tsserver"
end
if ts_server_name and lspconfig[ts_server_name] and type(lspconfig[ts_server_name].setup) == "function" then
  lspconfig[ts_server_name].setup({
    capabilities = capabilities,
    -- If you use an external formatter like prettier/biome, optionally disable tsserver formatting:
    -- on_attach = function(client)
    --   client.server_capabilities.documentFormattingProvider = false
    -- end,
  })
end

-- Telescope keymaps
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "[F]ind [F]iles" })

-- Handy LSP keymaps (buffer-local on attach)
local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
  end
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "K",  vim.lsp.buf.hover)
  map("n", "<leader>rn", vim.lsp.buf.rename)
  map("n", "<leader>ca", vim.lsp.buf.code_action)
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)
end

-- Attach on every server
local orig_setup = lspconfig.util.default_config.on_attach
lspconfig.util.default_config.on_attach = function(client, bufnr)
  if orig_setup then orig_setup(client, bufnr) end
  on_attach(client, bufnr)
end
