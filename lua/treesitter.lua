return {
    "nvim-treesitter/nvim-treesitter",
    -- IMPORTANT: We are going to let Neovim 0.12.0 handle the core 
    -- and ONLY use the plugin for downloading parsers.
    config = function()
        -- 1. Use the new 0.12.0 way to flatten if needed
        -- 2. Disable the problematic features
        require("nvim-treesitter.configs").setup({
            ensure_installed = { "lua", "vimdoc", "c", "markdown" },
            
            -- If 0.12.0 is crashing on highlights, turn this OFF.
            -- Neovim 0.12 has its own internal highlighter now.
            highlight = { 
                enable = false, 
            },
            
            -- Disable indent as it often uses the broken 'range' method
            indent = { enable = false },
        })
    end
}
