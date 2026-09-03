local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt

return {
	s(
		"newfile",
		fmt(
			[[
package {};

public class {} {{
    {}
}}
]],
			{
				f(function()
					local dir = vim.fn.expand("%:p:h")
					local rel = dir:match("[/\\]java[/\\](.+)$") or vim.fn.fnamemodify(dir, ":t")
					return (rel:gsub("[/\\]", "."))
				end),
				f(function()
					return vim.fn.expand("%:t:r")
				end),
				i(1),
			}
		)
	),
	s(
		"builder",
		fmt(
			[[
public {} with{}({} {}) {{
    this.{} = {};
    return this;
}}
]],
			{ i(1, "Builder"), i(2, "Prop"), i(3, "Type"), i(4, "value"), i(5, "field"), rep(4) }
		)
	),
}
