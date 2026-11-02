return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		keywords = {
			TODO = { color = "purple" },
			NOTE = { color = "green" },
			WARN = { color = "orange" },
			HLP = { icon = " ", color = "purple" },
			HLG = { icon = " ", color = "green" },
			HLR = { icon = " ", color = "red" },
			HLB = { icon = " ", color = "blue" },
			HLY = { icon = " ", color = "yellow" },
		},
		-- HL* only highlight in the buffer; this ripgrep pattern leaves them out of picker/quickfix/Trouble lists
		search = {
			pattern = [[\b(TODO|FIX|FIXME|BUG|FIXIT|ISSUE|HACK|WARN|WARNING|XXX|PERF|OPTIM|PERFORMANCE|OPTIMIZE|NOTE|INFO|TEST|TESTING|PASSED|FAILED):]],
		},
		colors = {
			red = { "#ff5555" },
			blue = { "#8be9fd" },
			yellow = { "#f1fa8c" },
			purple = { "#bd93f9" },
			green = { "#50fa7b" },
			orange = { "#ffb86c" },
		},
	},
	keys = {
		{
			"<leader>ft",
			function()
				Snacks.picker.todo_comments()
			end,
			desc = "Find Todo comments (Project)",
		},
		{
			"<F5>",
			function()
				Snacks.picker.todo_comments({
					keywords = { "TODO", "FIX", "WARN" },
					cwd = vim.fn.expand("%:p:h"),
				})
			end,
			desc = "Find Todo comments (Current Dir)",
		},
		{
			"<leader>fC",
			function()
				Snacks.picker.todo_comments({ cwd = vim.fn.expand("%:p:h") })
			end,
			desc = "Todo comments in Current Dir",
		},
	},
}
