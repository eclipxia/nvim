return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = { "MunifTanjim/nui.nvim" },
	-- command line only: messages/notify/lsp stay native (notifications go through Snacks)
	opts = {
		cmdline = { enabled = true, view = "cmdline_popup" },
		messages = { enabled = false },
		notify = { enabled = false },
		popupmenu = { enabled = false },
		lsp = {
			progress = { enabled = false },
			hover = { enabled = false },
			signature = { enabled = false },
			message = { enabled = false },
		},
	},
}
