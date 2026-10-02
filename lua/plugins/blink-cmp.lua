return {
	"saghen/blink.cmp",
	-- loaded before the first InsertEnter so show_on_insert fires on it
	event = "VeryLazy",
	version = "1.*",
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = "make install_jsregexp",
		},
		"rafamadriz/friendly-snippets",
		"onsails/lspkind.nvim",
		"erooke/blink-cmp-latex",
	},
	config = function()
		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/luasnippets" })

		local lspkind = require("lspkind")

		-- ponytail: name-based. LSP carries no "declared on this type" flag, so the
		-- generic members inherited from Object are listed out and sorted last.
		-- Add names per language if a server surfaces others.
		local inherited = {
			-- System.Object (C#)
			ToString = true,
			GetHashCode = true,
			GetType = true,
			Equals = true,
			ReferenceEquals = true,
			MemberwiseClone = true,
			-- java.lang.Object
			toString = true,
			hashCode = true,
			getClass = true,
			equals = true,
			notify = true,
			notifyAll = true,
			wait = true,
			clone = true,
			finalize = true,
		}

		require("blink.cmp").setup({
			snippets = { preset = "luasnip" },

			keymap = {
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				-- default preset puts this on <C-k>, which is taken above
				["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
				-- <C-S-*> needs a terminal that reports it (kitty protocol; in tmux,
				-- `extended-keys on`). Plain <C-K> is the same key as <C-k>.
				["<C-S-k>"] = { "scroll_signature_up", "fallback" },
				["<C-S-j>"] = { "scroll_signature_down", "fallback" },
			},

			completion = {
				-- noselect: don't auto-accept the top item on <CR>, require an
				-- explicit select first (matches the old cmp confirm({select=false}))
				list = { selection = { preselect = false } },
				documentation = { auto_show = true },
				trigger = {
					show_on_insert = true,
				},

				menu = {
					draw = {
						columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
						components = {
							-- same icon glyphs the old lspkind.cmp_format() rendered
							kind_icon = {
								text = function(ctx)
									return lspkind.symbolic(ctx.kind) .. ctx.icon_gap
								end,
							},
							-- maxwidth = 50 from the old lspkind.cmp_format() call
							label = { width = { fill = true, max = 50 } },
						},
					},
				},
			},

			sources = {
				default = { "lsp", "snippets", "buffer", "path" },
				-- LaTeX symbol completion, only active inside $...$ / $$...$$ in markdown
				per_filetype = { markdown = { "latex", "lsp", "snippets", "buffer", "path" } },
				providers = {
					latex = { name = "Latex", module = "blink-cmp-latex", opts = { insert_command = false } },
				},
			},

			fuzzy = {
				sorts = {
					-- snippets always sort after LSP items (methods/fields/attributes first)
					function(a, b)
						local a_snip, b_snip = a.source_id == "snippets", b.source_id == "snippets"
						if a_snip ~= b_snip then
							return b_snip
						end
					end,
					"exact",
					-- then the type's own members, before inherited/dunder ones
					function(a, b)
						local a_inh = inherited[a.label] or a.label:sub(1, 2) == "__"
						local b_inh = inherited[b.label] or b.label:sub(1, 2) == "__"
						if a_inh ~= b_inh then
							return b_inh
						end
					end,
					"score",
					"kind",
					"sort_text",
					"label",
				},
			},
			-- everything else is blink's default: trigger on ( and , only, no
			-- popup while typing a keyword, docs stay in the completion window
			signature = { enabled = false }, -- inline version lives in settings.lua
		})
	end,
}
