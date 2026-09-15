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
            python = { "isort", "black" },
            java = { "organize_java_imports", "lsp_format" },
            cs = { "csharpier" },
            sql = { "sql_formatter", "sql_go_newline" },
            html = { "prettierd" },
            css = { "css_beautify" },
        },
        formatters = {
            stylua = {
                prepend_args = { "--column-width", "110" },
            },
            black = {
                prepend_args = { "--line-length", "110" },
            },
            sql_formatter = {
                -- Only --language/-l and --config/-c are real CLI flags; tabWidth
                -- and friends are config keys, so they go through -c as JSON.
                -- Passing them as flags makes sql-formatter exit 2 and conform
                -- silently skip the step.
                prepend_args = {
                    "--language",
                    "tsql",
                    "--config",
                    vim.json.encode({
                        tabWidth = 4,
                        expressionWidth = 50,
                        keywordCase = "preserve",
                    }),
                },
            },
            css_beautify = {
                prepend_args = { "--no-selector-separator-newline" },
            },
            sql_go_newline = {
                -- sql_formatter doesn't know the T-SQL "GO" batch separator,
                -- so it can end up sharing a line with other text; split it
                -- onto its own line.
                format = function(_, _, lines, callback)
                    local out = {}
                    for _, l in ipairs(lines) do
                        local rest = l
                        local before, after = rest:match("^(.-)%f[%a]GO%f[%A](.-)$")
                        if not before then
                            table.insert(out, l)
                        else
                            while before do
                                if before:match("%S") then
                                    table.insert(out, (before:gsub("^%s+", ""):gsub("%s+$", "")))
                                end
                                table.insert(out, "GO")
                                rest = after
                                before, after = rest:match("^(.-)%f[%a]GO%f[%A](.-)$")
                            end
                            if rest:match("%S") then
                                table.insert(out, (rest:gsub("^%s+", ""):gsub("%s+$", "")))
                            end
                        end
                    end
                    callback(nil, out)
                end,
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
            timeout_ms = 500,
            lsp_fallback = true,
        },
    },
}
