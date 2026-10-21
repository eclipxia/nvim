-- set while an auto-recovery (kill stale daemon + restart client) is in
-- flight, so a server that keeps failing doesn't loop; see on_exit.
local recovering = false

-- client ids we've already announced, so the "attached to <sln>" message
-- fires once per server and not once per C# buffer; cleared in on_exit.
local announced = {}
local vim = vim

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
			on_attach = function(client, bufnr)
				recovering = false

				if not announced[client.id] then
					announced[client.id] = true
					-- store holds the .sln/.slnx roslyn.nvim picked in solution
					-- mode; it's empty in project (.csproj) mode, where root_dir
					-- is the project directory.
					local sln = require("roslyn.store").get(client.id)
					vim.notify(
						sln and ("Attached -- solution " .. vim.fs.basename(sln))
							or ("Attached -- project " .. vim.fs.basename(client.config.root_dir or "?")),
						vim.log.levels.INFO,
						{ title = "roslyn.nvim" }
					)
				end
			end,
			on_exit = function(code, signal, client_id)
				announced[client_id] = nil

				-- code=1/signal=0 is roslyn-language-server's signature for
				-- "couldn't attach to the shared workspace daemon" -- almost
				-- always another Neovim session already holding this same
				-- project's Roslyn workspace, not a config problem.
				--
				-- There is exactly ONE Microsoft.CodeAnalysis.LanguageServer
				-- --daemon process per machine, shared by every C# project you
				-- have open -- not per-project -- so killing it also drops Roslyn
				-- for any other session attached to it. They recover the same way
				-- this session is about to: the next attach spawns a fresh daemon.
				--
				-- recovering guards against a kill/restart loop when the real
				-- cause isn't a stale daemon; on_attach clears it, so a genuine
				-- duplicate later in the session still gets one auto-recovery.
				if code ~= 1 or signal ~= 0 then
					return
				end
				if recovering then
					vim.schedule(function()
						vim.notify(
							"Roslyn server still exits immediately (code 1, signal 0) after "
								.. "killing the shared daemon. Check :LspLog.",
							vim.log.levels.WARN,
							{ title = "roslyn.nvim" }
						)
					end)
					return
				end
				recovering = true

				local kill = vim.fn.has("win32") == 1
						and { "taskkill", "/F", "/IM", "Microsoft.CodeAnalysis.LanguageServer.exe" }
					or { "pkill", "-f", "CodeAnalysis.LanguageServer.*--daemon" }

				vim.system(kill, {}, function()
					-- pkill returns once the signal is sent, not once the daemon is
					-- gone; give it a moment to exit and release the workspace
					-- before a new client tries to claim it. Bump if it still races.
					vim.defer_fn(function()
						-- Re-fire the FileType autocmd nvim.lsp.enable installed,
						-- which is what starts/attaches the client. A second
						-- vim.lsp.enable("roslyn") does NOT do it: it only
						-- doautoall's, which skips these buffers (verified).
						-- The first buffer starts the client; the rest resolve to
						-- the same root_dir and just attach to it.
						for _, buf in ipairs(vim.api.nvim_list_bufs()) do
							local ft = vim.bo[buf].filetype
							if ft == "cs" or ft == "razor" then
								vim.api.nvim_exec_autocmds("FileType", {
									buffer = buf,
									group = "nvim.lsp.enable",
									modeline = false,
								})
							end
						end
					end, 500)
				end)
			end,
		})

		local function link_xmldoc()
			local map = {
				xmlDocCommentName = "@tag",
				xmlDocCommentAttributeName = "@tag.attribute",
				xmlDocCommentAttributeValue = "@string",
				xmlDocCommentAttributeQuotes = "@string",
				xmlDocCommentDelimiter = "@tag.delimiter",
				xmlDocCommentText = "@comment",
				xmlDocCommentComment = "@comment",
				xmlDocCommentCDataSection = "@string",
				xmlDocCommentEntityReference = "@constant",
				xmlDocCommentProcessingInstruction = "@keyword",
			}
			for tok, target in pairs(map) do
				vim.api.nvim_set_hl(0, "@lsp.type." .. tok .. ".cs", { link = target })
			end
		end

		link_xmldoc()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = link_xmldoc })
		vim.api.nvim_set_hl(0, "@lsp.type.xmlDocCommentName.cs", { link = "Type" })
		vim.api.nvim_set_hl(0, "@lsp.type.xmlDocCommentAttributeName.cs", { link = "Special" })
		vim.api.nvim_set_hl(0, "@lsp.type.xmlDocCommentDelimiter.cs", { link = "Comment" })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "cs",
			callback = function(args)
				vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
			end,
		})

		vim.api.nvim_create_user_command("DotnetSlnAdd", function()
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

			vim.system({ "dotnet", "sln", sln, "add", csproj }, { text = true }, function(res)
				vim.schedule(function()
					if res.code == 0 then
						vim.notify(("Added %s to %s"):format(vim.fs.basename(csproj), vim.fs.basename(sln)))
					else
						vim.notify(res.stderr or "dotnet sln add failed", vim.log.levels.ERROR)
					end
				end)
			end)
		end, { desc = "Add current project's .csproj to the nearest .slnx/.sln" })
	end,
}
