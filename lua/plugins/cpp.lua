return {
	"Civitasv/cmake-tools.nvim",
	-- only("c") keeps the cvim profile's build tooling out of plain nvim and
	-- every other profile, same as roslyn.nvim does for csvim.
	cond = require("lang").only("c"),
	ft = { "c", "cpp", "cmake" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		cmake_build_directory = "build",
		-- Writes build/compile_commands.json and symlinks it to the project
		-- root, which is the only way clangd finds real include paths and
		-- compile flags -- without it clangd guesses and every #include is red.
		cmake_soft_link_compile_commands = true,
		cmake_dap_configuration = {
			name = "cpp",
			type = "codelldb",
			request = "launch",
			stopOnEntry = false,
			runInTerminal = true,
		},
	},
}
