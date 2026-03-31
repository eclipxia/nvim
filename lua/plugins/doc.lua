return {
    "jeangiraldoo/codedocs.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    },
    config = function()
		require("codedocs").setup({
			default_styles = {
				python = "Google"
			},
			styles = { -- Modifications to styles are done in the `styles` key
				python = { -- language name
					Google = { -- name of the style to customize
						func = { -- structure name
							sections = {
								parameters = {
									insert_gap_between = {
										enabled = true
									},
									items = {
										insert_gap_between = {
											enabled = true
										},
									},
								},
								returns = {
									items = {
										insert_gap_between = {
											enabled = true
										}
									},
								}
							}
						}
					},
				},
			}
		})
    end
}
