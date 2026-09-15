return {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    cmd = "Neogen",
    keys = {
        { "<leader>k", function() require("neogen").generate() end, desc = "Generate docstring" },
    },
    config = function()
        require("neogen").setup({
            languages = {
                python = {
                    template = {
                        annotation_convention = "google_docstrings",
                    },
                },
                cs = {
                    template = {
                        annotation_convention = "xmldoc",
                    },
                },
            },
        })
    end,
}
