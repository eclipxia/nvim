local autocommands = {
	{
		"BufEnter",
		{
			pattern = {
				"*.asm",
				"*.c",
				"*.cpp",
				"*.cs",
				"*.csx",
				"*.go",
				"*.h",
				"*.hpp",
				"*.java",
				"*.js",
				"*.jsx",
				"*.kdl",
				"*.md",
				"*.ps1",
				"*.py",
				"*.r",
				"*.rs",
				"*.s",
				"*.sh",
				"*.ts",
				"*.tsx",
				"*.zig",
				"*.sql",
			},
			callback = function()
				-- opt_local: vim.opt here would set the width globally, so it
				-- leaked into every other buffer until the next BufEnter reset it
				vim.opt_local.shiftwidth = 4
				vim.opt_local.tabstop = 4
			end,
		},
	},

	{
		-- neogen emits one literal tab per indent column when noexpandtab, so
		-- docstrings land 4 tabs deep in space-indented files
		"BufEnter",
		{
			pattern = { "*.cs", "*.csx", "*.py", "*.js", "*.jsx", "*.ts", "*.tsx" },
			callback = function()
				vim.opt_local.expandtab = true
			end,
		},
	},

	{
		"BufWinEnter",
		{
			pattern = { "*.md", "*.txt", "*.tex" },
			callback = function()
				-- vim.opt.textwidth = 200
				vim.opt_local.wrap = false
			end,
		},
	},

	{
		"BufEnter",
		{
			pattern = {
				"*.css",
				"*.hs",
				"*.html",
				"*.ipynb",
				"*.json",
				"*.lua",
				"*.nix",
				"*.rb",
				"*.svelte",
				"*.xml",
			},
			callback = function()
				vim.opt_local.shiftwidth = 2
				vim.opt_local.tabstop = 2
			end,
		},
	},
}

for _, autocmd in ipairs(autocommands) do
	vim.api.nvim_create_autocmd(autocmd[1], autocmd[2])
end

-- Spell checking only where prose lives. Global `vim.opt.spell = true` cost
-- 36.8ms of startup (the fr spellfile alone is ~32ms of that).
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit", "tex", "rst" },
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- :Gradle — pick a task from `gradle tasks --all` in Telescope and run it in a terminal split.
vim.api.nvim_create_user_command("Gradle", function()
	local root = vim.fs.root(
		0,
		{ "gradlew", "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts" }
	)
	if not root then
		return vim.notify("No Gradle project found", vim.log.levels.ERROR)
	end
	local gradle = vim.uv.fs_stat(root .. "/gradlew") and "./gradlew" or "gradle"
	vim.notify("Loading Gradle tasks...")
	vim.system({ gradle, "-q", "tasks", "--all" }, { text = true, cwd = root }, function(res)
		vim.schedule(function()
			if res.code ~= 0 then
				return vim.notify(res.stderr, vim.log.levels.ERROR)
			end
			-- `tasks --all` output: "Group tasks" / "-----" header, then "name - description" lines.
			local tasks, group, prev = {}, "Other", nil
			for line in res.stdout:gmatch("[^\n]+") do
				if line:match("^%-+$") and prev and prev:match(" tasks$") then
					group = prev:gsub(" tasks$", "")
				else
					local name, desc = line:match("^([%w:_%-%.]+) %- (.*)")
					name = name or line:match("^([%w:_%-%.]+)$")
					if name then
						table.insert(tasks, { group = group, name = name, desc = desc or "" })
					end
				end
				prev = line
			end
			local displayer = require("telescope.pickers.entry_display").create({
				separator = " ",
				items = { { width = 18 }, { width = 36 }, { remaining = true } },
			})
			require("telescope.pickers")
				.new({}, {
					prompt_title = "Gradle tasks",
					finder = require("telescope.finders").new_table({
						results = tasks,
						entry_maker = function(t)
							return {
								value = t,
								ordinal = t.group .. " " .. t.name .. " " .. t.desc,
								display = function()
									return displayer({
										{ t.group, "Comment" },
										{ t.name, "Function" },
										t.desc,
									})
								end,
							}
						end,
					}),
					sorter = require("telescope.config").values.generic_sorter({}),
					attach_mappings = function(bufnr)
						require("telescope.actions").select_default:replace(function()
							local sel = require("telescope.actions.state").get_selected_entry()
							require("telescope.actions").close(bufnr)
							if sel then
								local task = sel.value.name
								vim.cmd("botright split | lcd " .. vim.fn.fnameescape(root))
								vim.cmd.terminal(gradle .. " " .. task)
							end
						end)
						return true
					end,
				})
				:find()
		end)
	end)
end, {})
