return {
    -- 1. We now start with Mason as the primary plugin instead of lspconfig
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
            { "folke/lazydev.nvim", ft = "lua", opts = {} },
        },
        config = function()
            -- Setup Mason Core
            require("mason").setup()

            -- Setup Tool Installer (Linters/Formatters)
            require("mason-tool-installer").setup({
                ensure_installed = { "flake8", "pylint", "stylua" },
            })

            require("fidget").setup({})

            -- LSP Capabilities for Autocompletion
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities()
            )

            -- 2. Native Neovim 0.11 Setup via Mason-LSPConfig
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "rust_analyzer", "pyright", "clangd" },
                handlers = {
                    -- Default handler using native vim.lsp APIs
                    function(server_name)
                        vim.lsp.config(server_name, { 
                            capabilities = capabilities 
                        })
                        vim.lsp.enable(server_name)
                    end,

                    ["lua_ls"] = function()
                        vim.lsp.config("lua_ls", {
                            capabilities = capabilities,
                            settings = {
                                Lua = {
                                    diagnostics = { globals = { "vim" } },
                                    workspace = { checkThirdParty = false },
                                    runtime = { version = "LuaJIT" },
                                },
                            },
                        })
                        vim.lsp.enable("lua_ls")
                    end,

                    ["pyright"] = function()
                        vim.lsp.config("pyright", {
                            capabilities = capabilities,
                            settings = {
                                python = {
                                    pythonPath = "/home/eclipxia/Documents/school/password-manager/main/venv/bin/python",
                                },
                            },
                        })
                        vim.lsp.enable("pyright")
                    end,
                },
            })

            -- 3. Completion (Cmp)
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args) require("luasnip").lsp_expand(args.body) end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = "lazydev", group_index = 0 },
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })

            -- 4. Diagnostics
            vim.diagnostic.config({
                virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
                signs = { severity = { min = vim.diagnostic.severity.WARN } },
            })
        end,
    }
}
