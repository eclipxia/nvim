return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		notifier = {
			enabled = true,
			-- sqlserver.nvim's <C-s> menu reports its own transient "starting
			-- SQL Tools Service" state as an error while the service boots.
			filter = function(n)
				local msg = type(n.msg) == "string" and n.msg or ""
				return not msg:find("Entered unrecognised query state: starting SQL Tools Service", 1, true)
			end,
		},
		input = { enabled = true },
		picker = {
			enabled = true,
			sources = {
				buffers = {
					win = {
						input = { keys = { ["d"] = { "bufdelete", mode = "n" } } },
						list = { keys = { ["d"] = "bufdelete" } },
					},
				},
			},
		},
	},
	keys = {
		{
			"<leader>nh",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification history",
		},
		{
			"<leader>nx",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss notifications",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find files",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.grep()
			end,
			desc = "Live Grep",
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Tags",
		},
		{
			"<leader>re",
			function()
				Snacks.picker.registers()
			end,
			desc = "Registers",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git commits",
		},
		{
			"<leader>ws",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "Workspace symbols",
		},
	},
}
