return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add({
			{ "<leader>c", group = "code" }, -- code actions (LSP/jdtls)
			{ "<leader>r", group = "refactor" }, -- rename, restart LSP, registers
			{ "<leader>o", group = "organize" }, -- organize imports (jdtls)
			{ "<leader>v", group = "test" }, -- test class/method (jdtls)
		})
	end,
}
