-- general
vim.opt.shell = "/bin/sh"
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "rose-pine"
lvim.builtin.lualine.options.theme = "rose-pine"
vim.opt.background = "light";

-- keymappings [view all the defaults by pressing <leader>Lk]
-- TODO: remap caps to ctrl and change this
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

-- TODO: User Config for predefined plugins
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 1

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
}

-- Additional Mappings
lvim.builtin.which_key.mappings["s"]["T"] = { "<cmd>TodoTelescope<cr>", "Todo Comments" }
