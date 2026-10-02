return {
	"danymat/neogen",
	dependencies = "nvim-treesitter/nvim-treesitter",
	cmd = "Neogen",
	keys = {
		{
			"<leader>k",
			function()
				require("neogen").generate()
			end,
			desc = "Generate docstring",
		},
	},
	config = function()
		require("neogen").setup({
			languages = {
				python = {
					template = {
						annotation_convention = "google_docstrings",
					},
				},
				cs = {
					template = {
						annotation_convention = "xmldoc",
					},
				},

				-- neogen's JS locator returns the export_statement for
				-- `export class`, but the JS config only knows the
				-- class_declaration, so granulator crashed on nil data.
				-- (Also: `js` isn't a filetype; javascript is.)
				javascript = {
					template = {
						annotation_convention = "jsdoc",
					},
					parent = {
						class = {
							"function_declaration",
							"expression_statement",
							"variable_declaration",
							"class_declaration",
							"export_statement",
						},
					},
					data = {
						class = {
							["export_statement"] = {
								["0"] = {
									extract = function(_)
										return { [require("neogen.types.template").item.ClassName] = { "" } }
									end,
								},
							},
						},
					},
				},

				typescript = {
					template = {
						annotation_convention = "tsdoc",
					},
				},
			},
		})
	end,
}
