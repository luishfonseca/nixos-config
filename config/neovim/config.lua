-- general
vim.opt.shell = "/bin/sh"
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "rose-pine"
lvim.builtin.lualine.options.theme = "rose-pine"
vim.opt.background = "dark";

-- keymappings [view all the defaults by pressing <leader>Lk]
-- TODO: remap caps to ctrl and change this
lvim.leader = "space"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"

lvim.builtin.terminal.shade_terminals = false

lvim.builtin.terminal.on_open = function (_)
  if not os.getenv("DISPLAY") then
    vim.cmd("let $PINENTRY_USER_DATA=\"USE_TTY=1\"")
  end
end

lvim.builtin.terminal.on_close = function (_)
  vim.cmd("let $PINENTRY_USER_DATA=\"USE_TTY=0\"")
end

lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "nix",
  "go",
  "hcl",
  "vue",
}

lvim.builtin.treesitter.highlight.enabled = true

-- generic LSP settings

-- ---@usage disable automatic installation of servers
lvim.lsp.automatic_servers_installation = false

-- Lua LSP

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

local opts = {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      diagonostics = {
        globals = {'vim'},
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

require("lspconfig")["sumneko_lua"].setup(opts)

-- Nix LSP

require("lspconfig")["rnix"].setup({})

-- Go LSP

require("lspconfig").gopls.setup({})

-- HCL LSP

require("lspconfig").terraformls.setup({})

-- Volar LSP

require("lspconfig").volar.setup({
  cmd = { "yarn", "vue-language-server", "--stdio" },
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json' },
})

-- Tailwind CSS LSP

require("lspconfig").tailwindcss.setup({
  cmd = { "yarn", "tailwindcss-language-server", "--stdio" },
})

-- CSS LSP

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

require("lspconfig").cssls.setup({
  capabilities = capabilities,
  cmd = { "css-languageserver", "--stdio" },
})

-- Additional Plugins
lvim.plugins = {
  {"rose-pine/neovim"},
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup()
    end,
  },
  {"jghauser/mkdir.nvim"},
  {"tpope/vim-eunuch"},
  {"stevearc/stickybuf.nvim"},
}

-- Additional Mappings
lvim.builtin.which_key.mappings["l"]["l"] = { "<cmd>:lua vim.diagnostic.open_float()<cr>", "Open Diagonostic Popup" }
lvim.builtin.which_key.mappings["s"]["T"] = { "<cmd>TodoTelescope<cr>", "Todo Comments" }
