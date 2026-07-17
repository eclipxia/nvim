return {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
        require("neogen").setup({
            languages = {
                python = {
                    template = {
                        annotation_convention = "google_docstrings",
                    },
                },
            },
        })

        vim.keymap.set("n", "<leader>k", function()
            require("neogen").generate()
        end, { desc = "Generate docstring" })
    end,
}
