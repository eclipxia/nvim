return{
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
		local ts = require('nvim-treesitter')

		ts.setup({
			ensure_installed = { "c", "lua", "vim", "vimdoc", "python", "javascript", "rust", "java" },
			sync_install = false,
			auto_install = true,
			highlight = { enable = true },
			fold = { enable = true },
			indent = { enable = true },
			-- Optional: Install parsers on startup if not using LazyDone
			-- install_dir = vim.fn.stdpath('data') .. '/site',
		})

		-- Enable features for all filetypes
		vim.api.nvim_create_autocmd('FileType', {
			pattern = { '*' },
			callback = function()
				if vim.treesitter.get_parser(nil, nil, { error = false }) then
					vim.treesitter.start()
				end
			end,
		})
	end,
}   
