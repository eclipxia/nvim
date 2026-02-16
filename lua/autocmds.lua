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
			},
			callback = function()
				vim.opt.shiftwidth = 4
				vim.opt.tabstop = 4
			end,
		},
	},

	{
		"BufWinEnter",
		{
			pattern = { "*.md", "*.txt", "*.tex" },
			callback = function()
				vim.opt.textwidth = 80
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
				vim.opt.shiftwidth = 2
				vim.opt.tabstop = 2
			end,
		},
	},
}

for _, autocmd in ipairs(autocommands) do
	vim.api.nvim_create_autocmd(autocmd[1], autocmd[2])
end

