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
		local author = vim.trim(vim.fn.system("git config user.name"))
		if author == "" then
			author = "Your Name"
		end
		local author_line = " * @author " .. author

		-- JSDoc: put "func" in this list too if you also want it on functions/methods.
		local js_author_types = { "class" }

		local jsdoc = vim.deepcopy(require("neogen.templates.jsdoc"))
		for idx = #jsdoc, 1, -1 do
			local e = jsdoc[idx]
			if
				e[2] == " */"
				and e[3]
				and e[3].type
				and vim.tbl_contains(e[3].type, "func")
				and not e[3].no_results
			then
				-- Normal doc block: @author goes just before the closing line.
				table.insert(jsdoc, idx, { nil, author_line, { type = js_author_types } })
			elseif e[2] == "/** $1 */" then
				-- Empty doc block: keep the normal one-liner for types without @author,
				-- and use a multi-line block only for the types that get it.
				local plain = vim.tbl_filter(function(t)
					return not vim.tbl_contains(js_author_types, t)
				end, e[3].type)
				local o = { no_results = true, type = js_author_types }
				local replacement = {}
				if #plain > 0 then
					table.insert(replacement, { nil, "/** $1 */", { no_results = true, type = plain } })
				end
				vim.list_extend(replacement, {
					{ nil, "/**", o },
					{ nil, " * $1", o },
					{ nil, author_line, o },
					{ nil, " */", o },
				})
				table.remove(jsdoc, idx)
				for k, ent in ipairs(replacement) do
					table.insert(jsdoc, idx + k - 1, ent)
				end
			end
		end

		-- Extra JSDoc tags neogen lacks: @enum (object/Object.freeze consts) and @type (other consts).
		for idx = #jsdoc, 1, -1 do
			local e = jsdoc[idx]
			if
				e[2] == " */"
				and e[3]
				and e[3].type
				and vim.tbl_contains(e[3].type, "func")
				and not e[3].no_results
			then
				table.insert(jsdoc, idx, { "const", " * @type {$1}", { type = { "func" } } })
				table.insert(jsdoc, idx, { "enum", " * @enum {$1}", { type = { "func" } } })
				break
			end
		end

		-- Wrap neogen's func extractors so declarations that aren't functions
		-- (`const X = Object.freeze({...})`, `const n = 1`) yield enum/const data.
		local base_func = require("neogen.configurations.javascript").data.func
		local fn_types =
			{ arrow_function = 1, function_expression = 1, ["function"] = 1, generator_function = 1 }
		local function wrap(key)
			local out = {}
			for idx, v in pairs(base_func[key]) do
				out[idx] = {
					extract = function(node)
						local decl = node:type() == "variable_declarator" and node or node:named_child(0)
						local val = decl and decl:type() == "variable_declarator" and decl:field("value")[1]
						if val and not fn_types[val:type()] then
							local txt = vim.treesitter.get_node_text(val, 0)
							if val:type() == "object" or txt:match("^Object%.freeze") then
								return { enum = { "" } }
							end
							return { const = { "" } }
						end
						return v.extract(node)
					end,
				}
			end
			return out
		end

		-- Javadoc: @author is only valid on types, so classes only.
		local javadoc = vim.deepcopy(require("neogen.templates.javadoc"))
		for idx = #javadoc, 1, -1 do
			local e = javadoc[idx]
			if e[2] == " */" then
				local opts = { type = { "class" }, no_results = e[3] and e[3].no_results or nil }
				table.insert(javadoc, idx, { nil, author_line, opts })
			end
		end

		local i = require("neogen.types.template").item
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

				java = {
					template = {
						annotation_convention = "javadoc",
						javadoc = javadoc,
					},
					-- neogen's Java config lacks enums and @interface annotations.
					parent = {
						class = {
							"class_declaration",
							"interface_declaration",
							"record_declaration",
							"enum_declaration",
							"annotation_type_declaration",
						},
					},
					data = {
						class = {
							["enum_declaration|annotation_type_declaration"] = {
								["0"] = {
									extract = function()
										return { [require("neogen.types.template").item.ClassName] = { "" } }
									end,
								},
							},
						},
					},
				},

				-- neogen's JS locator returns the export_statement for
				-- `export class`, but the JS config only knows the
				-- class_declaration, so granulator crashed on nil data.
				-- (Also: `js` isn't a filetype; javascript is.)
				javascript = {
					template = {
						annotation_convention = "jsdoc",
						jsdoc = jsdoc,
					},
					-- Each node type must belong to ONE neogen type: its reverse
					-- map is last-wins, so shared types picked func/class/type at random.
					parent = {
						class = { "class_declaration", "export_statement" },
						type = { "__none__" },
					},
					data = {
						func = {
							["lexical_declaration"] = wrap("lexical_declaration"),
							["expression_statement|variable_declaration"] = wrap(
								"expression_statement|variable_declaration"
							),
						},
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
