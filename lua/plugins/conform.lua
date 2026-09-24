return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            c = { "clang-format" },
            cpp = { "clang-format" },
            python = { "isort", "black" },
            java = { "organize_java_imports", "lsp_format" },
            cs = { "csharpier" },
            sql = { "sqlfluff" },
            html = { "prettierd" },
            javascript = { "prettierd" },
            typescript = { "prettierd" },
            javascriptreact = { "prettierd" },
            typescriptreact = { "prettierd" },
            css = { "css_beautify" },
        },
        formatters = {
            stylua = {
                prepend_args = { "--column-width", "110" },
            },
            black = {
                prepend_args = { "--line-length", "110" },
            },
            prettierd = {
                -- prettierd's CLI only accepts a single file path, not
                -- prettier flags (any extra arg errors with "Only a single
                -- file path is supported") -- PRETTIERD_DEFAULT_CONFIG is
                -- its documented way to set defaults, used only when no
                -- project .prettierrc is found. Matches the *.js/*.ts
                -- shiftwidth=4 buffer setting in lua/autocmds.lua.
                env = { PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/.prettierrc.json" },
            },
            css_beautify = {
                prepend_args = { "--no-selector-separator-newline" },
            },
            sqlfluff = {
                -- sqlfluff exits 1 (not 0) whenever it leaves behind a violation
                -- it can't safely auto-fix (e.g. an ambiguous quoted string) --
                -- the fixes it *did* make are still valid on stdout, so accept
                -- exit 1 too or conform discards the output and no-ops on save.
                exit_codes = { 0, 1 },
            },
            organize_java_imports = {
                -- Groups imports by top-level package (statics, then java.*,
                -- javax.*, then everything else alphabetically) with a blank
                -- line between groups. Eclipse/jdtls can't do this natively,
                -- so it runs as its own conform step before the LSP formatter.
                format = function(_, _, lines, callback)
                    for _, l in ipairs(lines) do
                        if l:match("^%s*//.*noformat") then
                            callback(nil, lines)
                            return
                        end
                    end

                    local first, last
                    local statics, groups, order = {}, {}, {}
                    for idx, l in ipairs(lines) do
                        local imp = l:match("^%s*(import%s+.-);?%s*$")
                        if imp then
                            first = first or idx
                            last = idx
                            imp = imp:gsub("%s*$", "") .. ";"
                            if imp:match("^import%s+static") then
                                table.insert(statics, imp)
                            else
                                local pkg = imp:match("^import%s+([%w_]+)%.") or ""
                                if not groups[pkg] then
                                    groups[pkg] = {}
                                    table.insert(order, pkg)
                                end
                                table.insert(groups[pkg], imp)
                            end
                        end
                    end

                    if not first then
                        callback(nil, lines)
                        return
                    end

                    table.sort(statics)
                    for _, g in pairs(groups) do
                        table.sort(g)
                    end
                    local rank = { java = 0, javax = 1 }
                    table.sort(order, function(a, b)
                        local ra, rb = rank[a] or 2, rank[b] or 2
                        if ra ~= rb then
                            return ra < rb
                        end
                        return a < b
                    end)

                    local out = {}
                    if #statics > 0 then
                        vim.list_extend(out, statics)
                        table.insert(out, "")
                    end
                    for i, pkg in ipairs(order) do
                        vim.list_extend(out, groups[pkg])
                        if i < #order then
                            table.insert(out, "")
                        end
                    end

                    local new_lines = {}
                    for i = 1, first - 1 do
                        table.insert(new_lines, lines[i])
                    end
                    vim.list_extend(new_lines, out)
                    for i = last + 1, #lines do
                        table.insert(new_lines, lines[i])
                    end

                    callback(nil, new_lines)
                end,
            },
        },
        format_on_save = {
            -- sqlfluff (Python, dialect+rules to load on every run) regularly
            -- takes 300-500ms even on a small file, well past the old 500ms
            -- ceiling meant for fast formatters like stylua/prettierd.
            timeout_ms = 3000,
            lsp_fallback = true,
        },
    },
}
