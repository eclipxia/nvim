return {
	"lewis6991/gitsigns.nvim",
	opts = {
		current_line_blame = true, -- show blame on the current line automatically
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 300, -- ms before it appears
			ignore_whitespace = false,
		},
		current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
	},
	vim.keymap.set(
		"n",
		"<leader>tb",
		"<cmd>Gitsigns toggle_current_line_blame<CR>",
		{ desc = "Toggle git blame" }
	),
}
