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
	}
}
