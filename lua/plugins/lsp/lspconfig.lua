return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            { "antosha417/nvim-lsp-file-operations", config = true },
            -- Use lazydev instead of neodev (neodev is deprecated)
            { "folke/lazydev.nvim", ft = "lua", opts = {} },
        },
        config = function()
            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            local capabilities = cmp_nvim_lsp.default_capabilities()
            local keymap = vim.keymap

            -- LSP Attach Mappings
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }
                    local set = function(mode, keys, cmd, desc)
                        opts.desc = desc
                        keymap.set(mode, keys, cmd, opts)
                    end

                    -- jdtls (lua/plugins/java.lua) is itself an LSP client, so it
                    -- triggers this autocmd too. It sets its own K/gd/<leader>ca/
                    -- <leader>rn with jdtls-aware commands; skip those here so the
                    -- two attach hooks don't clobber each other and which-key shows
                    -- only the java-nvim binds on java buffers.
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    local is_jdtls = client and client.name == "jdtls"

                    set("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references")
                    set("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                    if not is_jdtls then
                        set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Show LSP definitions")
                    end
                    set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations")
                    set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions")
                    if not is_jdtls then
                        set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "See available code actions")
                        set("n", "<leader>rn", vim.lsp.buf.rename, "Smart rename")
                    end
                    set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Show buffer diagnostics")
                    set("n", "<leader>d", vim.diagnostic.open_float, "Show line diagnostics")
										set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Go to previous diagnostic")
										set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Go to next diagnostic")
                    if not is_jdtls then
                        set("n", "K", vim.lsp.buf.hover, "Show documentation")
                    end
                    set("n", "<leader>rs", ":LspRestart<CR>", "Restart LSP")
                end,
            })

            -- Configure Mason Handlers with Neovim 0.11+ syntax
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "rust_analyzer", "pyright", "clangd" },
                handlers = {
                    -- Default handler
                    function(server_name)
                        vim.lsp.config(server_name, { capabilities = capabilities })
                        vim.lsp.enable(server_name)
                    end,

                    ["lua_ls"] = function()
                        vim.lsp.config("lua_ls", {
                            capabilities = capabilities,
                            settings = {
                                Lua = {
                                    completion = { callSnippet = "Replace" },
                                    diagnostics = { globals = { "vim" } },
                                    workspace = { checkThirdParty = false },
                                    runtime = { version = "LuaJIT" },
                                },
                            },
                        })
                        vim.lsp.enable("lua_ls")
                    end,


                    ["svelte"] = function()
                        vim.lsp.config("svelte", {
                            capabilities = capabilities,
                            on_attach = function(client)
                                vim.api.nvim_create_autocmd("BufWritePost", {
                                    pattern = { "*.js", "*.ts" },
                                    callback = function(ctx)
                                        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                                    end,
                                })
                            end,
                        })
                        vim.lsp.enable("svelte")
                    end,

                    ["graphql"] = function()
                        vim.lsp.config("graphql", {
                            capabilities = capabilities,
                            filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
                        })
                        vim.lsp.enable("graphql")
                    end,

                    ["emmet_ls"] = function()
                        vim.lsp.config("emmet_ls", {
                            capabilities = capabilities,
                            filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
                        })
                        vim.lsp.enable("emmet_ls")
                    end,
                },
            })

            -- Diagnostics
            vim.diagnostic.config({
                virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
                signs = { severity = { min = vim.diagnostic.severity.WARN } },
            })
        end,
    },
}
