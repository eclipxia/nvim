function ColorMyPencils(color)
	color = color or "dracula"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
	{
		"Mofiqul/dracula.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("dracula").setup({
				colors = {
					bg = "#000000",  -- pure black background
					black = "#000000",  -- also override the "black" color
				},
			})
			ColorMyPencils("dracula")
		end,
	},
	{
		"navarasu/onedark.nvim",
		lazy = true,
		config = function()
			require('onedark').setup {
				colors = {
					bg0 = "#000000",
					bg1 = "#000000",
					fg = "#dddddd",
				},
				style = 'darker'
			}
		end
	},
	{
		"kartikp10/noctis.nvim",
		lazy = true,
		dependencies = { "rktjmp/lush.nvim" },
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		config = function()
			require('rose-pine').setup({
				disable_background = true,
			})
		end
	},
}
