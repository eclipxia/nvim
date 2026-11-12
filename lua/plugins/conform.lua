return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			python = { "isort", "black" },
			java = { "organize_java_imports", "lsp_format" },
			cs = { "lsp_format" },
			sql = { "sqlfluff", "align_sql_columns", "align_sql_values" },
			html = { "prettierd" },
			javascript = { "prettierd" },
			typescript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescriptreact = { "prettierd" },
			css = { "prettierd" },
			xml = { "xmlformatter" },
		},
		formatters = {
			stylua = {
				prepend_args = { "--column-width", "110" },
			},
			black = {
				prepend_args = { "--line-length", "110" },
			},
			prettierd = {
				-- prettierd's CLI only accepts a single file path, not
				-- prettier flags (any extra arg errors with "Only a single
				-- file path is supported") -- PRETTIERD_DEFAULT_CONFIG is
				-- its documented way to set defaults, used only when no
				-- project .prettierrc is found. Matches the *.js/*.ts
				-- shiftwidth=4 buffer setting in lua/autocmds.lua.
				env = { PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/.prettierrc.json" },
			},
			sqlfluff = {
				-- sqlfluff exits 1 (not 0) whenever it leaves behind a violation
				-- it can't safely auto-fix (e.g. an ambiguous quoted string) --
				-- the fixes it *did* make are still valid on stdout, so accept
				-- exit 1 too or conform discards the output and no-ops on save.
				exit_codes = { 0, 1 },
			},
			align_sql_values = {
				-- INSERT ... VALUES, DECLARE, procedure parameters and SET @var aligned in columns
				-- (lua/sql_values.lua). Runs last so sqlfluff can't collapse the spacing.
				format = function(_, _, lines, callback)
					callback(nil, require("sql_values")(lines))
				end,
			},
			align_sql_columns = {
				-- Runs after sqlfluff (which collapses every run of spaces to one):
				-- inside CREATE TABLE ( ... ), pads the name and type of each column
				-- definition so the three columns line up. Constraint lines
				-- (CONSTRAINT, PRIMARY, FOREIGN, ...) are left untouched.
				format = function(_, _, lines, callback)
					-- ( minus ) outside of '...' strings
					local function paren_balance(t)
						local d, in_str, i = 0, false, 1
						while i <= #t do
							local c = t:sub(i, i)
							if in_str then
								if c == "'" then
									if t:sub(i + 1, i + 1) == "'" then
										i = i + 1
									else
										in_str = false
									end
								end
							elseif c == "'" then
								in_str = true
							elseif c == "(" then
								d = d + 1
							elseif c == ")" then
								d = d - 1
							end
							i = i + 1
						end
						return d
					end

					-- a CHECK (...) that spans several lines is joined back into one line first,
					-- so the layout below is rebuilt from scratch (idempotent)
					local function join_open_checks(ls)
						local res, i = {}, 1
						while i <= #ls do
							local cur = ls[i]
							if
								cur:upper():match("^%s*CONSTRAINT.-%f[%w]CHECK%s*%(")
								or cur:upper():match("^%s*CHECK%s*%(")
							then
								while paren_balance(cur) > 0 and ls[i + 1] do
									i = i + 1
									cur = cur .. " " .. vim.trim(ls[i])
								end
								cur = cur:gsub("%(%s+", "("):gsub("%s+%)", ")")
							end
							res[#res + 1] = cur
							i = i + 1
						end
						return res
					end

					-- "a AND b OR c BETWEEN 1 AND 5" -> { "a", "b", "c BETWEEN 1 AND 5" }, { "AND", "OR" }
					-- (top level only; the AND of a BETWEEN is not a separator)
					local function split_bool(s)
						local parts, ops, start, depth, in_str, between, i = {}, {}, 1, 0, false, false, 1
						local u = s:upper()
						while i <= #s do
							local c = s:sub(i, i)
							if in_str then
								if c == "'" then
									if s:sub(i + 1, i + 1) == "'" then
										i = i + 1
									else
										in_str = false
									end
								end
							elseif c == "'" then
								in_str = true
							elseif c == "(" then
								depth = depth + 1
							elseif c == ")" then
								depth = depth - 1
							elseif depth == 0 and not s:sub(i - 1, i - 1):match("[%w_]") then
								if u:match("^BETWEEN%f[%W]", i) then
									between = true
								elseif u:match("^AND%f[%W]", i) then
									if between then
										between = false
									else
										parts[#parts + 1] = vim.trim(s:sub(start, i - 1))
										ops[#ops + 1] = "AND"
										i = i + 2
										start = i + 1
									end
								elseif u:match("^OR%f[%W]", i) then
									parts[#parts + 1] = vim.trim(s:sub(start, i - 1))
									ops[#ops + 1] = "OR"
									i = i + 1
									start = i + 1
								end
							end
							i = i + 1
						end
						parts[#parts + 1] = vim.trim(s:sub(start))
						return parts, ops
					end

					lines = join_open_checks(lines)
					local skip = {
						CONSTRAINT = true,
						PRIMARY = true,
						FOREIGN = true,
						UNIQUE = true,
						CHECK = true,
						INDEX = true,
						REFERENCES = true,
						ON = true,
					}
					local out, block, in_table = {}, nil, false

					local function flush()
						if not block then
							return
						end
						local wn, wt = 0, 0
						for _, c in ipairs(block) do
							wn, wt = math.max(wn, #c.name), math.max(wt, #c.type)
						end
						for _, c in ipairs(block) do
							local line = c.indent .. c.name .. string.rep(" ", wn - #c.name + 1) .. c.type
							if c.rest ~= "" then
								-- a bare trailing comma hugs the type, no padding before it
								line = line
									.. (c.rest:sub(1, 1) == "," and "" or string.rep(" ", wt - #c.type + 1))
									.. c.rest
							end
							out[c.idx] = line
						end
						block = nil
					end

					local cons_kw =
						{ PRIMARY = true, UNIQUE = true, CHECK = true, FOREIGN = true, DEFAULT = true }
					local cons_lead -- indent of the CONSTRAINT line currently being laid out
					for _, l in ipairs(lines) do
						table.insert(out, l)
						local lead = l:match("^%s*")
						local t = l:match("^%s*(.-)%s*$")
						local first = t:match("^(%u+)")
						local is_head = t:match("^CONSTRAINT%s")
							or t:match("^ADD%s+CONSTRAINT%s")
							or t:match("^ALTER%s+TABLE%s.-%sADD%s+CONSTRAINT%s")
						local function emit(def)
							-- FOREIGN KEY (...) REFERENCES ... gets one more line, everything else stays whole
							local fk, refs = def:match("^(FOREIGN%s+KEY%s*%b())%s+(REFERENCES.*)$")
							local chk = def:match("^CHECK%s*%b()")
							local parts, ops
							if chk then
								parts, ops = split_bool(chk:match("%((.*)%)$"))
							end
							if parts and #parts > 1 then
								-- CHECK (\n  a AND\n  b\n) : one condition per line, operator last
								table.insert(out, cons_lead .. "    CHECK (")
								for k, part in ipairs(parts) do
									table.insert(
										out,
										cons_lead .. "        " .. part .. (ops[k] and (" " .. ops[k]) or "")
									)
								end
								table.insert(out, cons_lead .. "    )" .. def:sub(#chk + 1))
							elseif fk then
								table.insert(out, cons_lead .. "    " .. fk)
								table.insert(out, cons_lead .. "    " .. refs)
							else
								table.insert(out, cons_lead .. "    " .. def)
							end
						end
						if is_head then
							-- every constraint: name on the first line, definition indented 4 deeper below
							cons_lead = lead
							local pre, post = t:match("^(.-CONSTRAINT%s+%S+)%s+(.+)$")
							local kw = post and post:match("^(%u+)")
							if kw and cons_kw[kw] then
								out[#out] = lead .. pre
								emit(post)
							end
						elseif cons_lead and (first == "REFERENCES" or cons_kw[first]) then
							-- definition already on its own line (e.g. sqlfluff re-indented it): re-indent
							table.remove(out)
							emit(t)
						else
							cons_lead = nil
							if not in_table then
								local low = l:lower()
								if
									low:match("^%s*create%s+table.*%(%s*$")
									or low:match("^%s*declare%s+@[%w_]+%s+table%s*%(%s*$")
									or low:match("^%s*create%s+type%s.-%sas%s+table%s*%(%s*$")
								then
									in_table, block = true, {}
								end
							elseif l:match("^%s*%)") then
								flush()
								in_table = false
							else
								local indent, name, tail = l:match('^(%s+)([%w_%[%]"]+)%s+(.-)%s*$')
								if name and not skip[name:upper()] then
									local ty, rest = tail:match("^([%w_]+%s*%b())%s*(.*)$")
									if not ty then
										ty, rest = tail:match("^([%w_]+)%s*(.*)$")
									end
									if ty then
										table.insert(
											block,
											{
												idx = #out,
												indent = indent,
												name = name,
												type = ty,
												rest = rest,
											}
										)
									end
								end
							end
						end
					end
					flush()
					callback(nil, out)
				end,
			},
			organize_java_imports = {
				-- Groups imports by top-level package (statics, then java.*,
				-- javax.*, then everything else alphabetically) with a blank
				-- line between groups. Eclipse/jdtls can't do this natively,
				-- so it runs as its own conform step before the LSP formatter.
				format = function(_, _, lines, callback)
					for _, l in ipairs(lines) do
						if l:match("^%s*//.*noformat") then
							callback(nil, lines)
							return
						end
					end

					local first, last
					local statics, groups, order = {}, {}, {}
					for idx, l in ipairs(lines) do
						local imp = l:match("^%s*(import%s+.-);?%s*$")
						if imp then
							first = first or idx
							last = idx
							imp = imp:gsub("%s*$", "") .. ";"
							if imp:match("^import%s+static") then
								table.insert(statics, imp)
							else
								local pkg = imp:match("^import%s+([%w_]+)%.") or ""
								if not groups[pkg] then
									groups[pkg] = {}
									table.insert(order, pkg)
								end
								table.insert(groups[pkg], imp)
							end
						end
					end

					if not first then
						callback(nil, lines)
						return
					end

					table.sort(statics)
					for _, g in pairs(groups) do
						table.sort(g)
					end
					local rank = { java = 0, javax = 1 }
					table.sort(order, function(a, b)
						local ra, rb = rank[a] or 2, rank[b] or 2
						if ra ~= rb then
							return ra < rb
						end
						return a < b
					end)

					local out = {}
					if #statics > 0 then
						vim.list_extend(out, statics)
						table.insert(out, "")
					end
					for i, pkg in ipairs(order) do
						vim.list_extend(out, groups[pkg])
						if i < #order then
							table.insert(out, "")
						end
					end

					local new_lines = {}
					for i = 1, first - 1 do
						table.insert(new_lines, lines[i])
					end
					vim.list_extend(new_lines, out)
					for i = last + 1, #lines do
						table.insert(new_lines, lines[i])
					end

					callback(nil, new_lines)
				end,
			},
		},
		format_on_save = {
			-- sqlfluff (Python, dialect+rules to load on every run) regularly
			-- takes 300-500ms even on a small file, well past the old 500ms
			-- ceiling meant for fast formatters like stylua/prettierd.
			timeout_ms = 3000,
			lsp_fallback = true,
		},
	},
}
