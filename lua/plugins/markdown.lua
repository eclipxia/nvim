return {
    'SCJangra/table-nvim',
    -- Keep lazy loading with 'ft' to only load the plugin for markdown
    ft = 'markdown', 
    
    config = function()
        -- 1. Setup the plugin
        require('table-nvim').setup({})

        local table_augroup = vim.api.nvim_create_augroup("TableNvimAutoRealign", { clear = true })

        vim.api.nvim_create_autocmd("BufWritePre", {
            group = table_augroup,
            pattern = "*.md",             desc = "Auto-realign Markdown tables before saving",
            callback = function()
                if vim.fn.exists(":TableRealign") == 1 then
                    vim.cmd("TableRealign")
                end
            end,
        })
    end,
}
