return {
    "kkoomen/vim-doge",
    -- Doge needs to install its internal generators
    build = ":call doge#install()",
    config = function()
        -- 1. Force the Google standard globally
        vim.g.doge_doc_standard_python = 'google'
        
        -- 2. Enable "live" mode (lets you jump through placeholders)
        vim.g.doge_enable_mappings = 1
        
        -- 3. Set your keymap
        -- Using <Plug> is the traditional way Doge handles the generate call
        vim.keymap.set("n", "<leader>k", "<Plug>(doge-generate)", { desc = "Doge Google Doc" })
        
        -- Optional: Keybinds to jump between the docstring fields
        -- (Doge usually defaults to <Tab> and <S-Tab> automatically)
    end
}
