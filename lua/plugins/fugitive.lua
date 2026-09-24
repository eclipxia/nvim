return {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gclog", "Gblame", "Gread", "Gwrite" },
    keys = {
        { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
        { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
        { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git diff" },
        { "<leader>gl", "<cmd>Git l<cr>", desc = "Git log (graph)" },
    },
}
