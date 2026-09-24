return{
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
		local ts = require('nvim-treesitter')

		-- main branch API: setup() only takes install_dir; highlight/indent/fold
		-- and ensure_installed/auto_install from the old configs plugin don't exist
		-- here, so parsers must be installed explicitly.
		ts.install({
			"c", "cpp", "cmake", "make", "lua", "vim", "vimdoc", "python", "javascript", "typescript", "tsx",
			"rust", "java", "c_sharp", "html", "css", "xml", "php", "sql",
		})

		-- Enable features for all filetypes except sql: tree-sitter-sql is
		-- ANSI-flavored and knows nothing about T-SQL keywords, so sql stays
		-- on Vim's regex syntax (extended in after/syntax/sql.vim) instead.
		vim.api.nvim_create_autocmd('FileType', {
			pattern = { '*' },
			callback = function(args)
				if args.match == 'sql' then
					return
				end
				if vim.treesitter.get_parser(nil, nil, { error = false }) then
					vim.treesitter.start()
				end
			end,
		})
	end,
}
