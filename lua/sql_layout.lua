-- Project SQL layout, applied after sqlfluff (which collapses all alignment):
--   1. CREATE/ALTER VIEW ... AS : the body is indented one level under AS
--   2. SELECT list              : the `AS "alias"` of consecutive plain columns line up
--   3. JOIN lines               : keyword, table, alias, ON columns and = line up
-- Idempotent: each step normalises before it aligns. Used by conform
-- (plugins/conform.lua, formatter "sql_layout").
local INDENT = "    "

local function width(s)
	return vim.fn.strdisplaywidth(s)
end

local function pad(s, w)
	return s .. string.rep(" ", w - width(s))
end

-- ( minus ) outside of '...' strings
local function paren_balance(t)
	local d, in_str = 0, false
	for i = 1, #t do
		local c = t:sub(i, i)
		if c == "'" then
			in_str = not in_str
		elseif not in_str then
			if c == "(" then
				d = d + 1
			elseif c == ")" then
				d = d - 1
			end
		end
	end
	return d
end

local function is_blank(l)
	return l:match("^%s*$") ~= nil
end

-- 1. body of a view, from the line after `AS` to the next GO / CREATE / ALTER
local function indent_view_body(lines)
	local out, in_head, in_body, body = {}, false, false, {}

	local function flush()
		local min
		for _, l in ipairs(body) do
			if not is_blank(l) then
				local lead = #l:match("^%s*")
				min = min and math.min(min, lead) or lead
			end
		end
		for _, l in ipairs(body) do
			out[#out + 1] = is_blank(l) and l or (INDENT .. l:sub(min + 1))
		end
		body, in_body = {}, false
	end

	for _, l in ipairs(lines) do
		local u = l:upper()
		if in_body then
			if u:match("^%s*GO%s*$") or u:match("^%s*CREATE%s") or u:match("^%s*ALTER%s") then
				flush()
				out[#out + 1] = l
			else
				body[#body + 1] = l
			end
		else
			out[#out + 1] = l
			if
				u:match("^%s*CREATE%s+OR%s+ALTER%s+VIEW%s")
				or u:match("^%s*CREATE%s+VIEW%s")
				or u:match("^%s*ALTER%s+VIEW%s")
			then
				in_head = true
			elseif in_head and u:match("^%s*AS%s*$") then
				in_head, in_body = false, true
			end
		end
	end
	if in_body then
		flush()
	end
	return out
end

-- 2. `expr AS alias,` lines between SELECT and FROM, grouped while consecutive
local function align_select_aliases(lines)
	local out, in_select, group = {}, false, {}

	local function flush()
		local w = 0
		for _, g in ipairs(group) do
			w = math.max(w, width(g.expr))
		end
		for _, g in ipairs(group) do
			out[g.idx] = g.indent .. pad(g.expr, w) .. " AS " .. g.alias
		end
		group = {}
	end

	for _, l in ipairs(lines) do
		out[#out + 1] = l
		local u = l:upper()
		if u:match("^%s*SELECT%s*$") then
			in_select = true
		elseif u:match("^%s*FROM%s") or u:match("^%s*FROM$") then
			flush()
			in_select = false
		elseif in_select then
			local indent, expr, alias = l:match("^(%s*)(.-)%s+[Aa][Ss]%s+(.+)$")
			if expr and expr ~= "" and expr:upper() ~= "END" and paren_balance(expr) == 0 then
				group[#group + 1] = { idx = #out, indent = indent, expr = expr, alias = alias }
			else
				flush()
			end
		end
	end
	flush()
	return out
end

-- 3. `<x> JOIN table AS alias ON a = b [AND ...]` lines, grouped while consecutive
local function align_joins(lines)
	local out, group = {}, {}

	local function flush()
		local wk, wt, wa, wl = 0, 0, 0, 0
		for _, g in ipairs(group) do
			wk, wt = math.max(wk, width(g.kw)), math.max(wt, width(g.tbl))
			wa, wl = math.max(wa, width(g.alias)), math.max(wl, width(g.left))
		end
		for _, g in ipairs(group) do
			out[g.idx] = g.indent
				.. pad(g.kw, wk)
				.. " "
				.. pad(g.tbl, wt)
				.. " AS "
				.. pad(g.alias, wa)
				.. " ON "
				.. pad(g.left, wl)
				.. " = "
				.. g.right
				.. g.rest
		end
		group = {}
	end

	for _, l in ipairs(lines) do
		out[#out + 1] = l
		local indent, kw, tbl, alias, left, right, rest =
			l:match("^(%s*)(%u[%u ]-JOIN)%s+(%S+)%s+AS%s+(%S+)%s+ON%s+(%S+)%s*=%s*(%S+)(.*)$")
		if kw then
			group[#group + 1] = {
				idx = #out,
				indent = indent,
				kw = kw,
				tbl = tbl,
				alias = alias,
				left = left,
				right = right,
				rest = rest,
			}
		else
			flush()
		end
	end
	flush()
	return out
end

return function(lines)
	return align_joins(align_select_aliases(indent_view_body(lines)))
end
