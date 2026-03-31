return {
    "mbbill/undotree",
    config = function()
        -- Optional: Configuration goes here
    end,
    keys = {
        { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle Undotree" }
    }
}
