return {
    {
        "mason-org/mason.nvim",
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
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            require("mason").setup()

            -- Setup Tool Installer (Linters/Formatters). Gated by NVIM_LANG
            -- so jvim/csvim/pvim only check their own tools on every start;
            -- plain nvim (NVIM_LANG unset) still checks everything.
            local lang = require("lang").active
            local by_lang = {
                python = { "flake8", "pylint", "black", "isort" },
                java = { "java-debug-adapter", "java-test", "checkstyle" },
                cs = { "netcoredbg", "csharpier" },
                c = { "clang-format", "codelldb" },
            }
            local tools = { "stylua", "prettierd", "sqlfluff", "eslint_d" }
            for l, list in pairs(by_lang) do
                if lang == nil or lang == l then
                    vim.list_extend(tools, list)
                end
            end
            require("mason-tool-installer").setup({ ensure_installed = tools })
        end,
    }
}
