-- Column alignment for statements that carry values: INSERT ... VALUES, DECLARE,
-- procedure/function parameters and SET @var = ...  Runs after sqlfluff (see
-- plugins/conform.lua, formatter "align_sql_values"). Anything it can't parse
-- safely is left exactly as it was.
local function width(s)
	return vim.fn.strdisplaywidth(s)
end

local function pad(s, w)
	return s .. string.rep(" ", w - width(s))
end

-- "a, 'x,y', f(1, 2)" -> { "a", "'x,y'", "f(1, 2)" } (top-level commas only); nil if unbalanced
local function split_cells(s)
	local cells, cur, depth, in_str, i = {}, {}, 0, false, 1
	while i <= #s do
		local c = s:sub(i, i)
		if in_str then
			cur[#cur + 1] = c
			if c == "'" then
				if s:sub(i + 1, i + 1) == "'" then
					cur[#cur + 1] = "'"
					i = i + 1
				else
					in_str = false
				end
			end
		elseif c == "'" then
			in_str = true
			cur[#cur + 1] = c
		elseif c == "," and depth == 0 then
			cells[#cells + 1] = vim.trim(table.concat(cur))
			cur = {}
		else
			if c == "(" then
				depth = depth + 1
			elseif c == ")" then
				depth = depth - 1
				if depth < 0 then
					return nil
				end
			end
			cur[#cur + 1] = c
		end
		i = i + 1
	end
	if in_str or depth ~= 0 then
		return nil
	end
	cells[#cells + 1] = vim.trim(table.concat(cur))
	return cells
end

-- "(a, b)" row line -> cells, terminator ("," / ";" / "")
local function parse_row(t)
	local body, term = t:match("^%((.*)%)%s*([,;]?)$")
	local cells = body and split_cells(body)
	return cells, term
end

-- INSERT INTO t [(cols)] VALUES (..), (..); starting at lines[i]
-- returns the replacement lines and the next index, or nil to leave it alone
local function insert_block(lines, i)
	local l = lines[i]
	local lead, t = l:match("^(%s*)(.-)%s*$")
	local tbl = t:match("^INSERT%s+INTO%s+([^%s%(]+)")
	if not tbl then
		return nil
	end
	local rest = vim.trim((t:gsub("^INSERT%s+INTO%s+[^%s%(]+", "", 1)))
	local j, cols = i, nil

	local function take_cols(s)
		local c = s:match("^%b()")
		if c then
			cols = split_cells(c:sub(2, -2))
			return vim.trim(s:sub(#c + 1))
		end
		return s
	end

	rest = take_cols(rest)
	if rest == "" and not cols then
		local nxt = lines[j + 1] and vim.trim(lines[j + 1])
		if nxt and nxt:match("^%b()$") then
			cols = split_cells(nxt:sub(2, -2))
			j = j + 1
		end
	end
	if rest == "" then
		local nxt = lines[j + 1] and vim.trim(lines[j + 1])
		if not (nxt and nxt:match("^VALUES")) then
			return nil
		end
		j = j + 1
		rest = vim.trim((nxt:gsub("^VALUES", "", 1)))
	elseif rest:match("^VALUES") then
		rest = vim.trim((rest:gsub("^VALUES", "", 1)))
	else
		return nil
	end

	local rows, n = {}, nil
	local function add(row_text)
		local cells, term = parse_row(row_text)
		if not cells or (n and #cells ~= n) or (cols and #cells ~= #cols) then
			return false
		end
		n = #cells
		rows[#rows + 1] = { cells = cells, term = term }
		return true
	end
	if rest ~= "" and not add(rest) then
		return nil
	end
	while not (#rows > 0 and rows[#rows].term ~= ",") do
		j = j + 1
		local row = lines[j] and vim.trim(lines[j])
		if not row or not add(row) then
			return nil
		end
	end
	if cols and #cols ~= n then
		return nil
	end

	local w = {}
	local function measure(cells)
		for k, c in ipairs(cells) do
			w[k] = math.max(w[k] or 0, width(c))
		end
	end
	for _, r in ipairs(rows) do
		measure(r.cells)
	end
	if cols then
		measure(cols)
	end
	local function fmt(cells)
		local parts = {}
		for k, c in ipairs(cells) do
			parts[k] = k < #cells and pad(c .. ",", w[k] + 1) .. " " or c
		end
		return "(" .. table.concat(parts) .. ")"
	end

	local out = { lead .. "INSERT INTO " .. tbl }
	if cols then
		out[#out + 1] = lead .. "    " .. fmt(cols)
	end
	out[#out + 1] = lead .. "VALUES"
	for _, r in ipairs(rows) do
		out[#out + 1] = lead .. "    " .. fmt(r.cells) .. r.term
	end
	return out, j + 1
end

-- DECLARE @a INT = 1;  /  proc parameters:  @a INT = NULL,
-- aligns name / type / rest over a run of consecutive such lines
local function parse_decl(l, in_header)
	local lead, name, tail = l:match("^(%s*)DECLARE%s+(@[%w_]+)%s+(.-)%s*$")
	local kind = "DECLARE"
	if not name and in_header then
		lead, name, tail = l:match("^(%s+)(@[%w_]+)%s+(.-)%s*$")
		kind = ""
	end
	if not name then
		return nil
	end
	local ty = tail:match("^([%w_%.]+%s*%b())") or tail:match("^([%w_%.]+)")
	if not ty or tail:upper():match("^TABLE") then
		return nil
	end
	return { lead = lead, kind = kind, name = name, type = ty, rest = vim.trim(tail:sub(#ty + 1)) }
end

local function flush_decls(group, out)
	local wn, wt = 0, 0
	for _, d in ipairs(group) do
		wn, wt = math.max(wn, #d.name), math.max(wt, width(d.type))
	end
	for _, d in ipairs(group) do
		local line = d.lead .. (d.kind ~= "" and d.kind .. " " or "") .. pad(d.name, wn)
		if d.rest == "" then
			line = line .. " " .. d.type
		elseif d.rest:match("^[,;]") then
			line = line .. " " .. d.type .. d.rest
		else
			line = line .. " " .. pad(d.type, wt) .. " " .. d.rest
		end
		out[#out + 1] = line
	end
end

-- SET @a = 1; consecutive lines get their "=" aligned
local function flush_sets(group, out)
	local w = 0
	for _, s in ipairs(group) do
		w = math.max(w, #s.name)
	end
	for _, s in ipairs(group) do
		out[#out + 1] = s.lead .. "SET " .. pad(s.name, w) .. " = " .. s.value
	end
end

-- UPDATE ... SET a = 1,\n    bb = 2  ->  "=" aligned (the SET line and its continuation lines)
local COL = '([%w_%.%[%]"]+)'
local function update_set(lines, i)
	-- "UPDATE t SET a = 1, b = 2" on one line: SET moves to its own line first
	local up, setpart = lines[i]:match("^(%s*UPDATE%s+%S+)%s+(SET%s.*)$")
	if up then
		local tmp = vim.list_slice(lines, i)
		tmp[1] = up:match("^%s*") .. setpart
		local r, n = update_set(tmp, 1)
		if not r then
			return nil
		end
		table.insert(r, 1, up)
		return r, i + n - 1
	end
	local lead, col, val = lines[i]:match("^(%s*)SET%s+" .. COL .. "%s*=%s*(.-)%s*$")
	local rows, j
	local cells = lead and split_cells(val)
	if cells and #cells > 1 and cells[#cells] ~= "" then
		-- several assignments on the SET line: one per line
		rows, j = { { col = col, val = cells[1] .. "," } }, i
		for k = 2, #cells do
			local c, v = cells[k]:match("^" .. COL .. "%s*=%s*(.+)$")
			if not c then
				return nil
			end
			rows[#rows + 1] = { col = c, val = k < #cells and v .. "," or v }
		end
	elseif cells then
		rows, j = { { col = col, val = val } }, i
	elseif lines[i]:match("^%s*SET%s*$") then
		lead, rows, j = lines[i]:match("^(%s*)"), {}, i
	else
		return nil
	end
	while #rows == 0 or (rows[#rows].val:sub(-1) == ",") do
		local c, v = (lines[j + 1] or ""):match("^%s+" .. COL .. "%s*=%s*(.-)%s*$")
		if not c or not split_cells(v) then
			break
		end
		rows[#rows + 1] = { col = c, val = v }
		j = j + 1
	end
	if #rows == 0 then
		return nil
	end
	local w = 0
	for _, r in ipairs(rows) do
		w = math.max(w, width(r.col))
	end
	local out = {}
	local bare = lines[i]:match("^%s*SET%s*$")
	if bare then
		out[1] = lead .. "SET"
	end
	for k, r in ipairs(rows) do
		local prefix = (k == 1 and not bare) and (lead .. "SET ") or (lead .. "    ")
		out[#out + 1] = prefix .. pad(r.col, w) .. " = " .. r.val
	end
	return out, j + 1
end

-- SELECT\n    expr AS alias,  ->  the AS keywords line up (one target per line)
local function select_aliases(lines, i)
	local t = vim.trim(lines[i]):upper()
	if not (t == "SELECT" or t == "SELECT DISTINCT" or t:match("^SELECT TOP %d+$")) then
		return nil
	end
	local base = #lines[i]:match("^%s*")
	local j, first = i, nil
	local items = {}
	while lines[j + 1] and vim.trim(lines[j + 1]) ~= "" and #lines[j + 1]:match("^%s*") > base do
		j = j + 1
		local lead = lines[j]:match("^%s*")
		first = first or #lead
		if #lead == first then
			local expr, alias, comma = lines[j]:match('^%s+(.-)%s+AS%s+([%w_%[%]"]+)(,?)%s*$')
			local ue = expr and expr:upper()
			if expr and ue ~= "END" and expr:sub(1, 1) ~= ")" and split_cells(expr) then
				items[#items + 1] = { idx = j, lead = lead, expr = expr, alias = alias, comma = comma }
			end
		end
	end
	if #items == 0 then
		return nil
	end
	local w = 0
	for _, it in ipairs(items) do
		w = math.max(w, width(it.expr))
	end
	local repl = {}
	for _, it in ipairs(items) do
		repl[it.idx] = it.lead .. pad(it.expr, w) .. " AS " .. it.alias .. it.comma
	end
	local out = { lines[i] }
	for k = i + 1, j do
		out[#out + 1] = repl[k] or lines[k]
	end
	return out, j + 1
end

return function(lines)
	local out, i, in_header = {}, 1, false
	local decls, sets = {}, {}
	local function flush()
		if #decls > 0 then
			flush_decls(decls, out)
			decls = {}
		end
		if #sets > 0 then
			flush_sets(sets, out)
			sets = {}
		end
	end

	while i <= #lines do
		local l = lines[i]
		local t = vim.trim(l)
		local d = parse_decl(l, in_header)
		local lead, name, value = l:match("^(%s*)SET%s+(@[%w_]+)%s*=%s*(.-)%s*$")

		if d then
			if #sets > 0 then
				flush()
			end
			decls[#decls + 1] = d
			i = i + 1
		elseif name then
			if #decls > 0 then
				flush()
			end
			sets[#sets + 1] = { lead = lead, name = name, value = value }
			i = i + 1
		else
			flush()
			if
				t:upper():match("^CREATE%s+PROC")
				or t:upper():match("^CREATE%s+OR%s+ALTER%s+PROC")
				or t:upper():match("^CREATE%s+FUNCTION")
				or t:upper():match("^ALTER%s+PROC")
				or t:upper():match("^CREATE%s+OR%s+ALTER%s+FUNCTION")
			then
				in_header = true
			elseif t:upper():match("^AS$") or t:upper():match("^BEGIN") or t:upper():match("^RETURNS") then
				in_header = false
			end
			local block, nxt = update_set(lines, i)
			if not block then
				block, nxt = select_aliases(lines, i)
			end
			if not block then
				block, nxt = insert_block(lines, i)
			end
			if block then
				vim.list_extend(out, block)
				i = nxt
			else
				out[#out + 1] = l
				i = i + 1
			end
		end
	end
	flush()
	return out
end
