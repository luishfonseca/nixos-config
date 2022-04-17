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
lvim.builtin.nvimtree.show_icons.git = 1

lvim.builtin.terminal.shade_terminals = false

local function _on_open (_)
  vim.cmd("let $PINENTRY_USER_DATA=\"USE_TTY=1\"")
end

local function _on_close (_)
  vim.cmd("let $PINENTRY_USER_DATA=\"USE_TTY=0\"")
end

lvim.builtin.terminal.on_open = _on_open
lvim.builtin.terminal.on_close = _on_close

local lazygit = require("toggleterm.terminal").Terminal:new({
  cmd = "lazygit",
  direction = "float",
  hidden = true,
  on_open = _on_open,
  on_close = _on_close,
})

function LazyGitToggle()
  lazygit:toggle()
end

lvim.builtin.which_key.mappings["g"]["g"] = { "<cmd>lua LazyGitToggle()<cr>", "LazyGit" }


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
  {"jghauser/mkdir.nvim"},
  {"tpope/vim-eunuch"},
  {"stevearc/stickybuf.nvim"},
}

-- Additional Mappings
lvim.builtin.which_key.mappings["s"]["T"] = { "<cmd>TodoTelescope<cr>", "Todo Comments" }
