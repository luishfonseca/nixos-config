-- Bootstrap packer.nvim

vim.cmd('packadd packer.nvim')

local packer = require('packer')

packer.init({
    git = {
		clone_timeout = 350,
    },
    display = {
		title = "Packer",
		done_sym = "",
		error_syn = "×",
		keybindings = {
			toggle_info = "o"
		}
    }
})

packer.startup(function(use)

    use {
		"wbthomason/packer.nvim",
		opt = true
    }

    use {
		"sainnhe/gruvbox-material",
		config = function()
			vim.cmd("colorscheme gruvbox-material")
		end
    }

    use {
        "lewis6991/impatient.nvim",
		opt = true,
		config = function()
			require('impatient')
		end
    }

    use {
    	"nvim-treesitter/nvim-treesitter",
    	run = ":TSUpdate",
    	after = "impatient.nvim",
    	config = function()
			require('nvim-treesitter.configs').setup {
				ensure_installed = "all",

				highlight = { enable = true },
				indent = { enable = true },

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

end)
