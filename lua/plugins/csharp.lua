return {
	"seblyng/roslyn.nvim",
	-- ft = "cs": the plugin's own plugin/roslyn.lua calls
	-- vim.lsp.enable("roslyn") on load, which would start the client before
	-- our settings/on_attach below are registered -- except lazy.nvim always
	-- runs a plugin's `init` at startup, before any ft/event-triggered load,
	-- so putting the vim.lsp.config() call in `init` (instead of `config`)
	-- guarantees it lands first regardless of when roslyn.nvim itself loads.
	--
	-- cond = only("cs") restricts registration (and thus `init` running at
	-- all) to the csvim profile (NVIM_LANG=cs); plain nvim/jvim/pvim never
	-- pay for it.
	cond = require("lang").only("cs"),
	ft = { "cs", "razor" },
	init = function()
		vim.lsp.config("roslyn", {
			settings = {
				["csharp|inlay_hints"] = {
					csharp_enable_inlay_hints_for_parameters = true,
					csharp_enable_inlay_hints_for_literal_parameters = true,
					csharp_enable_inlay_hints_for_indexer_parameters = true,
					csharp_enable_inlay_hints_for_object_creation_parameters = true,
					csharp_enable_inlay_hints_for_other_parameters = true,
				},
			},
			on_attach = function(_, bufnr)
				-- On "(" for an empty call, insert the declared parameter
				-- names as a snippet (like jdtls does for Java). On ",",
				-- just show the signature float for the next parameter.
				-- True when the cursor sits right after an unmatched "("
				-- with nothing but whitespace before it and a ")" right
				-- after it -- i.e. an empty argument list, regardless of
				-- exactly how autopairs got it there.
				local function in_empty_call_parens()
					local win = vim.api.nvim_get_current_win()
					local cur = vim.api.nvim_win_get_cursor(win)
					local col = cur[2]
					local line = vim.api.nvim_get_current_line()
					if line:sub(col + 1, col + 1) ~= ")" then
						return false
					end
					local before = line:sub(1, col)
					local depth = 0
					for i = #before, 1, -1 do
						local c = before:sub(i, i)
						if c == ")" then
							depth = depth + 1
						elseif c == "(" then
							if depth == 0 then
								return before:sub(i + 1) == ""
							end
							depth = depth - 1
						end
					end
					return false
				end

				local function fill_params()
					local win = vim.api.nvim_get_current_win()
					if vim.api.nvim_get_current_buf() ~= bufnr then
						return
					end
					if not in_empty_call_parens() then
						return
					end

					local params = vim.lsp.util.make_position_params(win, "utf-16")
					vim.lsp.buf_request(bufnr, "textDocument/signatureHelp", params, function(err, res)
						if err or not res or not res.signatures or #res.signatures == 0 then
							return
						end
						local sig = res.signatures[(res.activeSignature or 0) + 1]
						if not sig.parameters or #sig.parameters == 0 then
							return
						end
						local parts = {}
						for i, p in ipairs(sig.parameters) do
							local name = p.label
							if type(name) == "table" then
								name = sig.label:sub(name[1] + 1, name[2])
							end
							parts[#parts + 1] = ("${%d:%s}"):format(i, name)
						end
						require("luasnip").lsp_expand(table.concat(parts, ", "))
					end)
				end

				vim.api.nvim_create_autocmd("InsertCharPre", {
					buffer = bufnr,
					callback = function()
						-- deferred past the LSP didChange debounce so the
						-- server sees the just-typed character
						if vim.v.char == "(" then
							vim.defer_fn(fill_params, 200)
						elseif vim.v.char == "," then
							vim.defer_fn(vim.lsp.buf.signature_help, 200)
						end
					end,
				})
			end,
			on_exit = function(code, signal, _)
				-- code=1/signal=0 is roslyn-language-server's signature for
				-- "couldn't attach to the shared workspace daemon" -- almost
				-- always another Neovim session already holding this same
				-- project's Roslyn workspace, not a config problem.
				if code ~= 1 or signal ~= 0 then
					return
				end

				-- There is exactly ONE Microsoft.CodeAnalysis.LanguageServer
				-- --daemon process per machine, shared by every C# project you
				-- have open -- not per-project. Killing it recovers this
				-- session but also drops Roslyn for any other project/session
				-- currently attached to it, so always ask first.
				if vim.fn.has("win32") == 1 then
					vim.notify(
						"Roslyn server exited immediately (code 1, signal 0), usually because "
							.. "another Neovim session already has this project open in Roslyn. "
							.. "Close duplicate sessions and reopen this file.",
						vim.log.levels.WARN,
						{ title = "roslyn.nvim" }
					)
					return
				end

				vim.schedule(function()
					local choice = vim.fn.confirm(
						"Roslyn server exited immediately (code 1, signal 0) -- likely another "
							.. "Neovim session already holds this project's Roslyn workspace.\n\n"
							.. "Kill the shared roslyn daemon to recover? This also drops Roslyn "
							.. "for any OTHER C# project/session currently using it.",
						"&Kill it\n&Leave it",
						2
					)
					if choice ~= 1 then
						return
					end

					vim.system(
						{ "pgrep", "-f", "CodeAnalysis.LanguageServer.*--daemon" },
						{ text = true },
						function(res)
							vim.schedule(function()
								local pids = {}
								for pid in (res.stdout or ""):gmatch("%d+") do
									table.insert(pids, pid)
								end
								if #pids == 0 then
									vim.notify("No roslyn daemon process found to kill.", vim.log.levels.WARN, { title = "roslyn.nvim" })
									return
								end
								for _, pid in ipairs(pids) do
									vim.system({ "kill", pid })
								end
								vim.notify(
									"Killed roslyn daemon (pid " .. table.concat(pids, ", ") .. "). Reopen the file for a fresh client.",
									vim.log.levels.WARN,
									{ title = "roslyn.nvim" }
								)
							end)
						end
					)
				end)
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "cs",
			callback = function(args)
				vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
			end,
		})

		vim.api.nvim_create_user_command(
			"DotnetSlnAdd",
			function()
				local csproj = vim.fs.find(function(name)
					return name:match("%.csproj$")
				end, { upward = true, path = vim.fn.expand("%:p:h") })[1]
				if not csproj then
					vim.notify("No .csproj found", vim.log.levels.ERROR)
					return
				end

				local sln = vim.fs.find(function(name)
					return name:match("%.slnx?$")
				end, {
					upward = true,
					path = vim.fn.fnamemodify(csproj, ":h"),
				})[1]
				if not sln then
					vim.notify("No .sln/.slnx found", vim.log.levels.ERROR)
					return
				end

				vim.system(
					{ "dotnet", "sln", sln, "add", csproj },
					{ text = true },
					function(res)
						vim.schedule(function()
							if res.code == 0 then
								vim.notify(
									("Added %s to %s"):format(
										vim.fs.basename(csproj),
										vim.fs.basename(sln)
									)
								)
							else
								vim.notify(
									res.stderr or "dotnet sln add failed",
									vim.log.levels.ERROR
								)
							end
						end)
					end
				)
			end,
			{ desc = "Add current project's .csproj to the nearest .slnx/.sln" }
		)
	end,
}
