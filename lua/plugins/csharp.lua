return {
    "seblyng/roslyn.nvim",
    ft = "cs",
    opts = {
        settings = {
            ["csharp|inlay_hints"] = {
                csharp_enable_inlay_hints_for_parameters = true,
                csharp_enable_inlay_hints_for_literal_parameters = true,
                csharp_enable_inlay_hints_for_indexer_parameters = true,
                csharp_enable_inlay_hints_for_object_creation_parameters = true,
                csharp_enable_inlay_hints_for_other_parameters = true,
            },
        },
    },
    config = function(_, opts)
        require("roslyn").setup(opts)

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "cs",
            callback = function(args)
                vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
            end,
        })

        vim.api.nvim_create_user_command("DotnetSlnAdd", function()
            local csproj = vim.fs.find(function(name)
                return name:match("%.csproj$")
            end, { upward = true, path = vim.fn.expand("%:p:h") })[1]
            if not csproj then
                vim.notify("No .csproj found", vim.log.levels.ERROR)
                return
            end

            local sln = vim.fs.find(function(name)
                return name:match("%.slnx?$")
            end, { upward = true, path = vim.fn.fnamemodify(csproj, ":h") })[1]
            if not sln then
                vim.notify("No .sln/.slnx found", vim.log.levels.ERROR)
                return
            end

            vim.system({ "dotnet", "sln", sln, "add", csproj }, { text = true }, function(res)
                vim.schedule(function()
                    if res.code == 0 then
                        vim.notify(("Added %s to %s"):format(vim.fs.basename(csproj), vim.fs.basename(sln)))
                    else
                        vim.notify(res.stderr or "dotnet sln add failed", vim.log.levels.ERROR)
                    end
                end)
            end)
        end, { desc = "Add current project's .csproj to the nearest .slnx/.sln" })
    end,
}
