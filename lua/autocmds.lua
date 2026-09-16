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
				"*.kdl",
				"*.md",
				"*.ps1",
				"*.py",
				"*.r",
				"*.rs",
				"*.s",
				"*.sh",
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
				"*.js",
				"*.json",
				"*.jsx",
				"*.lua",
				"*.nix",
				"*.rb",
				"*.svelte",
				"*.ts",
				"*.tsx",
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
