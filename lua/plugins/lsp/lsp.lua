return {
    {
        "williamboman/mason.nvim",
			opts = {
				registries = {
					'github:mason-org/mason-registry',
					'github:nvim-java/mason-registry',
				},
			},
        build = ":MasonUpdate",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "j-hui/fidget.nvim",
        },
        config = function()
            require("mason").setup()

            -- Setup Tool Installer (Linters/Formatters)
            require("mason-tool-installer").setup({
                ensure_installed = { "flake8", "pylint", "stylua", "black" },
            })

            require("fidget").setup({})
        end,
    }
}
