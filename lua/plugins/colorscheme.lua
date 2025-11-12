function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
	{ "Mofiqul/dracula.nvim",
  config = function()
    require("dracula").setup({
      colors = {
        bg = "#000000",  -- pure black background
        black = "#000000",  -- also override the "black" color
      },
    })
  end,
	},
	{
		"navarasu/onedark.nvim",
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			require('onedark').setup {
				colors = {
					bg0 = "#000000",
					bg1 = "#000000",
					fg = "#dddddd",
				},
				style = 'darker'
			}
			-- Enable theme
			require('onedark').load()
		end
	},
	{
    "kartikp10/noctis.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    config = function()
    end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
				require('rose-pine').setup({
						disable_background = true,
				})

				vim.cmd("colorscheme rose-pine")

				ColorMyPencils()
		end
	},
}
