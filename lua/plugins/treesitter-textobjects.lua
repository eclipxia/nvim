return {
	'nvim-treesitter/nvim-treesitter-textobjects',
	event = 'VeryLazy',
	config = function()
		require('nvim-treesitter-textobjects').setup({
			select = { lookahead = true },
			move = { set_jumps = true },
		})

		local select = require('nvim-treesitter-textobjects.select')
		for key, obj in pairs({
			['af'] = '@function.outer', ['if'] = '@function.inner',
			['ac'] = '@class.outer',    ['ic'] = '@class.inner',
			['aa'] = '@parameter.outer', ['ia'] = '@parameter.inner',
		}) do
			vim.keymap.set({ 'x', 'o' }, key, function() select.select_textobject(obj, 'textobjects') end)
		end

		local move = require('nvim-treesitter-textobjects.move')
		vim.keymap.set({ 'n', 'x', 'o' }, ']f', function() move.goto_next_start('@function.outer', 'textobjects') end)
		vim.keymap.set({ 'n', 'x', 'o' }, ']c', function() move.goto_next_start('@class.outer', 'textobjects') end)
		vim.keymap.set({ 'n', 'x', 'o' }, '[f', function() move.goto_previous_start('@function.outer', 'textobjects') end)
		vim.keymap.set({ 'n', 'x', 'o' }, '[c', function() move.goto_previous_start('@class.outer', 'textobjects') end)
	end,
}
