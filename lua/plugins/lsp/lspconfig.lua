return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
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

                    if client and client:supports_method("textDocument/inlayHint") then
                        vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
                    end
                end,
            })

            -- Inlay hints shift text as you type over them, so hide them in
            -- insert mode and restore on return to normal/visual.
            vim.api.nvim_create_autocmd("InsertEnter", {
                group = vim.api.nvim_create_augroup("UserInlayHintMode", {}),
                callback = function(ev)
                    vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
                end,
            })
            vim.api.nvim_create_autocmd("InsertLeave", {
                group = vim.api.nvim_create_augroup("UserInlayHintMode", { clear = false }),
                callback = function(ev)
                    for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
                        if client:supports_method("textDocument/inlayHint") then
                            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
                            break
                        end
                    end
                end,
            })

            -- mason-lspconfig v2 dropped `handlers`/`setup_handlers`: it now just
            -- installs servers and auto-enables the installed ones. Per-server
            -- tweaks go through vim.lsp.config(), and "*" is the default merged
            -- into every server.
            vim.lsp.config("*", { capabilities = capabilities })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        completion = { callSnippet = "Replace" },
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false },
                        runtime = { version = "LuaJIT" },
                    },
                },
            })

            -- @tailwind / @apply / @screen aren't real CSS at-rules, so
            -- vscode-css-language-server flags them. Silence just that.
            local css_lint = { unknownAtRules = "ignore" }
            vim.lsp.config("cssls", {
                settings = {
                    css = { lint = css_lint },
                    scss = { lint = css_lint },
                    less = { lint = css_lint },
                },
            })

            vim.lsp.config("svelte", {
                on_attach = function(client)
                    vim.api.nvim_create_autocmd("BufWritePost", {
                        pattern = { "*.js", "*.ts" },
                        callback = function(ctx)
                            client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                        end,
                    })
                end,
            })

            -- Point pyright at the project's own interpreter, since pyright
            -- doesn't auto-discover venvs on its own.
            local function project_python_path(root_dir)
                local bin = vim.fn.has("win32") == 1 and "Scripts/python.exe" or "bin/python"
                -- The shell's already-activated venv (tmux, direnv, etc.) wins
                -- over guessing a directory name, since a stale .venv/ left
                -- over in the project root would otherwise shadow it.
                if vim.env.VIRTUAL_ENV then
                    local candidate = vim.env.VIRTUAL_ENV .. "/" .. bin
                    if vim.fn.executable(candidate) == 1 then
                        return candidate
                    end
                end
                for _, dir in ipairs({ ".venv", "venv", ".env", "env" }) do
                    local candidate = root_dir .. "/" .. dir .. "/" .. bin
                    if vim.fn.executable(candidate) == 1 then
                        return candidate
                    end
                end
                local exe = vim.fn.exepath("python3")
                return exe ~= "" and exe or vim.fn.exepath("python")
            end

            vim.lsp.config("pyright", {
                settings = {
                    python = { analysis = { inlayHints = { callArgumentNames = "all" } } },
                },
                -- Native vim.lsp.config has no on_new_config hook (that was
                -- nvim-lspconfig-only); before_init is the real one, and it
                -- must mutate settings.python in place (not reassign) so the
                -- client's already-captured settings table picks it up.
                before_init = function(_, config)
                    config.settings.python.pythonPath = project_python_path(config.root_dir)
                end,
            })

            -- sqls has no project-local config file of its own: it only reads
            -- ~/.config/sqls/config.yml, a -c path, or initializationOptions.
            -- So pick up a per-project ".sqls.json" at the root ourselves and
            -- hand it over as connectionConfig. JSON rather than sqls' own YAML
            -- so vim.json.decode can read it with no extra dependency.
            vim.lsp.config("sqls", {
                root_markers = { ".sqls.json", "config.yml", ".git" },
                -- Go 1.23+ rejects certs with a negative serial number, which is
                -- exactly what azure-sql-edge self-signs on first boot, so every
                -- connection dies in the TLS handshake. Opt this process back into
                -- the old behaviour rather than relying on GODEBUG from the shell.
                cmd_env = { GODEBUG = "x509negativeserial=1" },
                before_init = function(params, config)
                    local root = config.root_dir
                    if root == nil or root == vim.NIL then
                        root = params.rootPath
                    end
                    if root == nil or root == vim.NIL then
                        return
                    end
                    local file = root .. "/.sqls.json"
                    if vim.fn.filereadable(file) == 1 then
                        local ok, conn = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
                        if not ok then
                            vim.notify("sqls: bad .sqls.json: " .. tostring(conn), vim.log.levels.ERROR)
                            return
                        end
                        params.initializationOptions =
                            vim.tbl_extend("force", params.initializationOptions or {}, { connectionConfig = conn })
                        return
                    end

                    -- No project config: fall back to a `--pgsql`/`--tsql` marker
                    -- comment on one of the first few lines of the buffer that
                    -- started this client, instead of silently inheriting whatever
                    -- driver happens to be default in ~/.config/sqls/config.yml.
                    local dialect_drivers = {
                        pgsql = "postgresql",
                        postgres = "postgresql",
                        postgresql = "postgresql",
                        tsql = "mssql",
                        mssql = "mssql",
                        mysql = "mysql",
                        sqlite = "sqlite3",
                        sqlite3 = "sqlite3",
                    }
                    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 5, false)) do
                        local marker = line:match("^%s*%-%-%s*(%a+)%s*$")
                        local driver = marker and dialect_drivers[marker:lower()]
                        if driver then
                            params.initializationOptions = vim.tbl_extend(
                                "force",
                                params.initializationOptions or {},
                                { connectionConfig = { driver = driver } }
                            )
                            return
                        end
                    end
                end,
            })

            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    -- clangd defaults to utf-8; nvim and every other client
                    -- here speak utf-16, and a mismatch makes nvim warn on
                    -- every multi-client buffer.
                    "--offset-encoding=utf-16",
                },
            })

            vim.api.nvim_create_user_command("ClangdSwitchSourceHeader", function()
                local client = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
                if not client then
                    return vim.notify("clangd not attached", vim.log.levels.ERROR)
                end
                client:request(
                    "textDocument/switchSourceHeader",
                    vim.lsp.util.make_text_document_params(),
                    function(err, res)
                        if err or not res then
                            return vim.notify("no matching source/header", vim.log.levels.WARN)
                        end
                        vim.cmd.edit(vim.uri_to_fname(res))
                    end
                )
            end, { desc = "Switch between C/C++ source and header" })

            -- ts_ls has inlay hints but ships them off by default; the
            -- LspAttach handler above only enables the feature when the
            -- client advertises support, which needs this turned on first.
            local ts_inlay_hints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
            }
            vim.lsp.config("ts_ls", {
                settings = {
                    javascript = { inlayHints = ts_inlay_hints },
                    typescript = { inlayHints = ts_inlay_hints },
                },
            })

            vim.lsp.config("graphql", {
                filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
            })

            vim.lsp.config("emmet_ls", {
                filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
            })

            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "rust_analyzer", "pyright", "clangd", "sqls", "html", "cssls", "tailwindcss", "ts_ls" },
            })

            -- Diagnostics
            vim.diagnostic.config({
                virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
                signs = { severity = { min = vim.diagnostic.severity.WARN } },
            })
        end,
    },
}
