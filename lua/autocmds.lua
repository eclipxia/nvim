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

-- Huge files (e.g. an 83MB SQL dump) freeze nvim: sqls re-tokenizes the whole
-- buffer on every change, treesitter/syntax re-parse it. Skip them above 1MB.
local big_file = 1024 * 1024
local function is_big(buf)
	local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
	return stat and stat.size > big_file
end

vim.api.nvim_create_autocmd("BufReadPre", {
	callback = function(ev)
		if is_big(ev.buf) then
			vim.b[ev.buf].bigfile = true
			vim.opt_local.syntax = "off"
			vim.opt_local.foldmethod = "manual"
			vim.opt_local.swapfile = false
			vim.opt_local.undolevels = -1
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		if vim.b[ev.buf].bigfile then
			vim.schedule(function()
				vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		if vim.b[ev.buf].bigfile then
			vim.treesitter.stop(ev.buf)
		end
	end,
})

-- Spell checking only where prose lives. Global `vim.opt.spell = true` cost
-- 36.8ms of startup (the fr spellfile alone is ~32ms of that).
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit", "tex", "rst" },
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- :Wnew <branch> [base] — worktree in ../<branch> for a new branch off main/master (or base), pushed upstream, then :cd into it.
vim.api.nvim_create_user_command("Wnew", function(opts)
	local branch, base = opts.fargs[1], opts.fargs[2]
	base = base
		or (
			vim.system({ "git", "rev-parse", "--verify", "--quiet", "main" }):wait().code == 0 and "main"
			or "master"
		)
	local path = "../" .. branch
	local res = vim.system({ "git", "worktree", "add", "-b", branch, path, base }, { text = true }):wait()
	if res.code ~= 0 then
		return vim.notify("Wnew: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
	end
	local push = vim.system(
		{ "git", "push", "--set-upstream", "origin", branch },
		{ text = true, cwd = path }
	)
		:wait()
	if push.code ~= 0 then
		vim.notify("Wnew: push failed: " .. vim.trim(push.stderr or ""), vim.log.levels.WARN)
	end
	vim.cmd.cd(vim.fn.fnameescape(path))
end, { nargs = "+", desc = "Create a worktree for a new branch off main/master (or a given base)" })

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
			local items = {}
			for _, t in ipairs(tasks) do
				items[#items + 1] = { text = t.group .. " " .. t.name .. " " .. t.desc, task = t }
			end
			Snacks.picker.pick({
				title = "Gradle tasks",
				items = items,
				format = function(item)
					local t = item.task
					return { { t.group .. " ", "Comment" }, { t.name .. " ", "Function" }, { t.desc } }
				end,
				confirm = function(picker, item)
					picker:close()
					if item then
						vim.cmd("botright split | lcd " .. vim.fn.fnameescape(root))
						vim.cmd.terminal(gradle .. " " .. item.task.name)
					end
				end,
			})
		end)
	end)
end, {})

-- sqls only parses MySQL/Postgres/SQLite style SQL. On T-SQL (GO batches,
-- DECLARE @vars, or a `-- tsql`/`-- mssql` marker) it spams parse errors and
-- can spin a core, so detach it there; Postgres etc. keep working.
local function looks_like_tsql(buf)
	for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		local l = line:lower()
		if
			l:match("^%s*go%s*$")
			or l:match("^%s*declare%s+@")
			or l:match("^%s*%-%-%s*t?sql%s*$")
			or l:match("^%s*%-%-%s*mssql%s*$")
		then
			return true
		end
	end
	return false
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client.name == "sqls" and looks_like_tsql(ev.buf) then
			vim.schedule(function()
				vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
			end)
		end
	end,
})

-- Don't leave language servers (e.g. a stuck sqls) running after nvim exits.
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		vim.lsp.stop_client(vim.lsp.get_clients(), true)
	end,
})
