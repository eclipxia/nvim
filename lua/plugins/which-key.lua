return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		plugins = {
			registers = false, -- disable the popup shown when pressing " in normal mode
		},
		-- NOT `triggers = {}`: that also disables which-key's own key
		-- interception, and plugins like sqlserver.nvim register their
		-- <leader>-prefixed maps ONLY as virtual which-key entries (no real
		-- vim.keymap.set fallback), so <leader>s stopped doing anything but
		-- the plain `s` (substitute-char) command. `delay` only affects when
		-- the popup auto-shows, not whether keys are captured -- set it
		-- absurdly high so it never fires on its own; `:WhichKey` still
		-- opens it on demand regardless of delay.
		delay = 24 * 60 * 60 * 1000,
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add({
			{ "<leader>c", group = "code" }, -- code actions (LSP/jdtls)
			{ "<leader>r", group = "refactor" }, -- rename, restart LSP, registers
			{ "<leader>o", group = "organize" }, -- organize imports (jdtls)
			{ "<leader>v", group = "test" }, -- test class/method (jdtls)
			{ "<leader>x", group = "debug" }, -- nvim-dap breakpoint/continue/step
		})
	end,
}
