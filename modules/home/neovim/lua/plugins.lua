-- Bootstrap packer.nvim
vim.cmd('packadd packer.nvim')

local packer = require('packer')

packer.init({
    git = {clone_timeout = 350},
    display = {
        title = "Packer",
        done_sym = "",
        error_syn = "×",
        keybindings = {toggle_info = "o"}
    }
})

packer.startup(function(use)

    use {"wbthomason/packer.nvim", opt = true}

    use {
        "sainnhe/gruvbox-material",
        config = function() vim.cmd("colorscheme gruvbox-material") end
    }

    use {
        "lewis6991/impatient.nvim",
        opt = true,
        config = function() require('impatient') end
    }

    use {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        after = "impatient.nvim",
        config = function()
            require('nvim-treesitter.configs').setup {
                ensure_installed = "all",

                highlight = {enable = true},
                indent = {enable = true},
                autopairs = {enable = true},

                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "gnn",
                        node_incremental = "gnn",
                        scope_incremental = "gns",
                        node_decremental = "gnp"
                    }
                }
            }
        end
    }

    use {
        "neovim/nvim-lspconfig",
        config = function()

            local nvim_lsp = require('lspconfig')

            -- Use an on_attach function to only map the following keys
            -- after the language server attaches to the current buffer
            local on_attach = function(client, bufnr)
                local function buf_set_keymap(...)
                    vim.api.nvim_buf_set_keymap(bufnr, ...)
                end
                local function buf_set_option(...)
                    vim.api.nvim_buf_set_option(bufnr, ...)
                end

                -- Enable completion triggered by <c-x><c-o>
                buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

                -- Mappings.
                local opts = {noremap = true, silent = true}

                -- See `:help vim.lsp.*` for documentation on any of the below functions
                -- LuaFormatter off
                buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
                buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
                buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
                buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
                buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
                buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
                buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
                buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
                buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
                buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
                buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
                buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
                buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
                buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
                -- LuaFormatter on
            end

            -- Use a loop to conveniently call 'setup' on multiple servers and
            -- map buffer local keybindings when the language server attaches
            local servers = {'pyright', 'rust_analyzer'}
            for _, lsp in ipairs(servers) do
                nvim_lsp[lsp].setup {
                    on_attach = on_attach,
                    flags = {debounce_text_changes = 150}
                }
            end

            -- Lua Language Server config

            local runtime_path = vim.split(package.path, ';')
            table.insert(runtime_path, "lua/?.lua")
            table.insert(runtime_path, "lua/?/init.lua")

            nvim_lsp.sumneko_lua.setup {
                cmd = {'lua-language-server'},
                settings = {
                    Lua = {
                        runtime = {version = 'LuaJIT', path = runtime_path},
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true)
                        },
                        diagnostics = {globals = {'vim'}},
                        telemetry = {enable = false}
                    }
                },
                on_attach = on_attach,
                flags = {debounce_text_changes = 150}
            }
        end
    }

    use {
        "hrsh7th/nvim-cmp",
        after = {"nvim-lspconfig", "nvim-autopairs"},
        config = function()
            local cmp = require('cmp')

            cmp.setup {
                preselect = cmp.PreselectMode.None,

                completion = {completeopt = "menu,menuone,noselect"},

                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end
                },

                mapping = {
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-u>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-c>"] = cmp.mapping.close()
                },

                sources = {
                    {name = "buffer"}, {name = "nvim_lua"}, {name = "nvim_lsp"},
                    {name = "luasnip"}, {name = "calc"}, {name = "path"}
                    -- { name = "neorg" },
                }
            }

            require('nvim-autopairs.completion.cmp').setup({
                map_cr = true,
                map_complete = true
            })

        end,

        requires = {
            {"hrsh7th/cmp-buffer", after = "nvim-cmp"},
            {"hrsh7th/cmp-nvim-lua", after = "nvim-cmp"},
            {"hrsh7th/cmp-nvim-lsp", after = "nvim-cmp"},
            {"saadparwaiz1/cmp_luasnip", after = "nvim-cmp"},
            {"hrsh7th/cmp-calc", after = "nvim-cmp"},
            {"hrsh7th/cmp-path", after = "nvim-cmp"}
        }
    }

    use {"L3MON4D3/LuaSnip", module = "cmp"}

    use {
        "windwp/nvim-autopairs",
        after = "nvim-treesitter",
        config = function()
            require('nvim-autopairs').setup {check_ts = true}
        end
    }

    use {'jghauser/mkdir.nvim', config = function() require('mkdir') end}

    use {"tpope/vim-sleuth"}

    use {
        "lukas-reineke/format.nvim",
        config = function()
            require('format').setup {
                ["*"] = {
                    {cmd = {"sed -i 's/[ \t]*$//'"}} -- Remove trailing whitespace
                },
                lua = {{cmd = {"lua-format"}}},
                nix = {{cmd = {"nixfmt"}}}
            }
        end,
        cmd = {"Format", "FormatWrite"}
    }

end)
