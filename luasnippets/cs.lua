local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt

local function cs_namespace()
	local file_dir = vim.fn.expand("%:p:h")
	local csproj = vim.fs.find(function(name)
		return name:match("%.csproj$")
	end, { path = file_dir, upward = true })[1]

	-- No .csproj found: fall back to path relative to cwd
	if not csproj then
		local rel = vim.fn.expand("%:.:h")
		if rel == "." or rel == "" then
			return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
		end
		return (rel:gsub("[/\\]", "."))
	end

	local root = vim.fs.dirname(csproj)
	local ns = vim.fn.fnamemodify(csproj, ":t:r") -- project name
	local rel = file_dir:sub(#root + 2) -- path below the project root
	if rel ~= "" then
		ns = ns .. "." .. (rel:gsub("[/\\]", "."))
	end
	return ns
end

return {
	s(
		"newfile",
		fmt(
			[[
namespace {};

public class {}
{{
    {}
}}
]],
			{
				f(cs_namespace),
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
public {} With{}({} {})
{{
    this.{} = {};
    return this;
}}
]],
			{ i(1, "Builder"), i(2, "Prop"), i(3, "Type"), i(4, "value"), i(5, "field"), rep(4) }
		)
	),
}
