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
		"BufEnter",
		{
			pattern = { "*.java", "*.cs", "*.csx", "*.py" },
			callback = function()
				vim.opt_local.textwidth = 120
				vim.opt_local.formatoptions:append("t")
			end,
		},
	},

	{
		"BufWritePre",
		{
			pattern = { "*.java", "*.cs", "*.csx", "*.py" },
			callback = function()
				local view = vim.fn.winsaveview()
				vim.cmd("keepjumps normal! gggqG")
				vim.fn.winrestview(view)
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
				vim.opt.shiftwidth = 2
				vim.opt.tabstop = 2
			end,
		},
	},
}

for _, autocmd in ipairs(autocommands) do
	vim.api.nvim_create_autocmd(autocmd[1], autocmd[2])
end
