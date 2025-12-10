return {
    'SCJangra/table-nvim',
    -- Keep lazy loading with 'ft' to only load the plugin for markdown
    ft = 'markdown', 
    
    config = function()
        -- 1. Setup the plugin
        require('table-nvim').setup({})

        -- 2. Define the global autocommand group (best practice)
        local table_augroup = vim.api.nvim_create_augroup("TableNvimAutoRealign", { clear = true })

        -- 3. Define the BufWritePre Autocommand globally
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = table_augroup,
            pattern = "*.md", -- Apply only to Markdown files
            desc = "Auto-realign Markdown tables before saving",
            callback = function()
                -- Check if the TableRealign command exists before executing.
                -- :h exists()
                if vim.fn.exists(":TableRealign") == 1 then
                    vim.cmd("TableRealign")
                end
                -- If it doesn't exist, we skip it. The 'ft' constraint ensures 
                -- this only runs on markdown files where the plugin should load.
            end,
        })
    end,
}
