-- Signature help for T-SQL without a language server (mssql_ls returns an
-- empty signatureHelp even when connected). Signatures come from:
--   * CREATE [OR ALTER] FUNCTION/PROCEDURE in the current buffer and in
--     <project root>/sql/*.sql (re-read when a file's mtime changes)
--   * a short built-in table below
-- at_cursor() returns { pre, active, post } (label split around the active
-- parameter) or nil when the cursor isn't inside a known call.
local M = {}

local builtins = {
	DATEDIFF = "datepart, startdate, enddate",
	DATEADD = "datepart, number, date",
	DATEPART = "datepart, date",
	DATENAME = "datepart, date",
	EOMONTH = "start_date, [month_to_add]",
	COALESCE = "expression1, expression2, ...",
	ISNULL = "check_expression, replacement_value",
	NULLIF = "expression1, expression2",
	IIF = "boolean_expression, true_value, false_value",
	CONVERT = "data_type, expression, [style]",
	TRY_CONVERT = "data_type, expression, [style]",
	FORMAT = "value, format, [culture]",
	CONCAT = "string1, string2, ...",
	SUBSTRING = "expression, start, length",
	REPLACE = "string, pattern, replacement",
	REPLICATE = "string, count",
	ROUND = "numeric_expression, length, [function]",
	STRING_AGG = "expression, separator",
	ENCRYPTBYPASSPHRASE = "passphrase, cleartext",
	DECRYPTBYPASSPHRASE = "passphrase, ciphertext",
	ENCRYPTBYKEY = "key_guid, cleartext",
	KEY_GUID = "key_name",
	OBJECT_ID = "object_name, [object_type]",
}

local function strip_comments(text)
	return (text:gsub("/%*.-%*/", ""):gsub("%-%-[^\n]*", ""))
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- split on commas outside (), [] and '...'
local function split_top(s)
	local parts, depth, instr, start = {}, 0, false, 1
	for i = 1, #s do
		local c = s:sub(i, i)
		if instr then
			if c == "'" then
				instr = false
			end
		elseif c == "'" then
			instr = true
		elseif c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = depth - 1
		elseif c == "," and depth == 0 then
			parts[#parts + 1] = trim(s:sub(start, i - 1))
			start = i + 1
		end
	end
	parts[#parts + 1] = trim(s:sub(start))
	return parts
end

local function key(name)
	return (name:gsub("^.*%.", ""):gsub("[%[%]]", ""):lower())
end

local function parse_defs(text, defs)
	text = strip_comments(text)
	local low, init = text:lower(), 1
	while true do
		local s1, e1, k1, n1 = low:find("create%s+or%s+alter%s+(%a+)%s+([%w_%.%[%]]+)", init)
		local s2, e2, k2, n2 = low:find("create%s+(%a+)%s+([%w_%.%[%]]+)", init)
		local e, kind, name
		if s1 and (not s2 or s1 <= s2) then
			e, kind, name = e1, k1, n1
		elseif s2 then
			e, kind, name = e2, k2, n2
		else
			break
		end
		init = e + 1
		if kind == "function" or kind == "procedure" or kind == "proc" then
			local rest = text:sub(e + 1)
			local body
			if rest:match("^%s*%(") then
				local open = rest:find("%(")
				local depth, close = 0, nil
				for i = open, #rest do
					local c = rest:sub(i, i)
					if c == "(" then
						depth = depth + 1
					elseif c == ")" then
						depth = depth - 1
						if depth == 0 then
							close = i
							break
						end
					end
				end
				body = close and rest:sub(open + 1, close - 1)
			else
				local as_at = rest:lower():find("%f[%w]as%f[%W]")
				body = as_at and rest:sub(1, as_at - 1)
			end
			if body then
				local params = {}
				for _, p in ipairs(split_top(body)) do
					p = p:gsub("%s+", " ")
					if p:sub(1, 1) == "@" then
						params[#params + 1] = p
					end
				end
				if #params > 0 then
					defs[key(name)] = {
						name = text:sub(e - #name + 1, e):gsub("^.*%.", ""),
						params = params,
						proc = kind ~= "function",
					}
				end
			end
		end
	end
end

local cache = {} -- path -> { mtime, defs }

local function project_defs(buf)
	local defs = {}
	local root = vim.fs.root(buf, { ".git", ".sqlfluff" })
	if root then
		for _, f in ipairs(vim.fn.glob(root .. "/sql/*.sql", false, true)) do
			local st = vim.uv.fs_stat(f)
			if st and st.size < 1024 * 1024 then
				local c = cache[f]
				if not c or c.mtime ~= st.mtime.sec then
					c = { mtime = st.mtime.sec, defs = {} }
					local fh = io.open(f, "r")
					if fh then
						parse_defs(fh:read("*a"), c.defs)
						fh:close()
					end
					cache[f] = c
				end
				for k, v in pairs(c.defs) do
					defs[k] = v
				end
			end
		end
	end
	parse_defs(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), defs)
	return defs
end

local function lookup(defs, name)
	local d = defs[key(name)]
	if d then
		return d.name, d.params, d.proc
	end
	local b = builtins[name:upper()]
	if b then
		return name:upper(), split_top(b), false
	end
end

local function make(name, params, idx, proc)
	idx = math.min(idx, #params)
	local open, close = proc and " " or "(", proc and "" or ")"
	local pre = name .. open .. table.concat(params, ", ", 1, idx - 1)
	if idx > 1 then
		pre = pre .. ", "
	end
	local post = idx < #params and (", " .. table.concat(params, ", ", idx + 1)) or ""
	return { pre = pre, active = params[idx], post = post .. close }
end

function M.at_cursor()
	local buf = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local lines = vim.api.nvim_buf_get_lines(buf, math.max(0, row - 40), row, false)
	lines[#lines] = lines[#lines]:sub(1, col)
	local text = table.concat(lines, "\n")
	local defs = project_defs(buf)

	-- walk the text up to the cursor keeping a stack of open parentheses
	local stack, instr = {}, false
	for i = 1, #text do
		local c = text:sub(i, i)
		if instr then
			if c == "'" then
				instr = false
			end
		elseif c == "'" then
			instr = true
		elseif c == "(" then
			local name = text:sub(1, i - 1):match("([%w_%.%[%]]+)%s*$")
			stack[#stack + 1] = { name = name, idx = 1 }
		elseif c == ")" then
			stack[#stack] = nil
		elseif c == "," and #stack > 0 then
			stack[#stack].idx = stack[#stack].idx + 1
		end
	end
	for i = #stack, 1, -1 do
		local f = stack[i]
		if f.name then
			local name, params, proc = lookup(defs, f.name)
			if name then
				return make(name, params, f.idx, proc)
			end
		end
	end

	-- EXEC proc a, b, ... on the cursor line (no parentheses)
	local line = lines[#lines]
	local pname, args = line:match("[Ee][Xx][Ee][Cc][Uu]?[Tt]?[Ee]?%s+([%w_%.%[%]]+)%s+(.*)$")
	if pname then
		local name, params, proc = lookup(defs, pname)
		if name and proc then
			return make(name, params, #split_top(args), true)
		end
	end
end

return M
