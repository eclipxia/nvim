return {
    "TheNoeTrevino/dadbod-ui.nvim",
    -- Same gating as sqlserver.lua: only the sqlvim profile (NVIM_LANG=sql).
    cond = require("lang").only("sql"),
    dependencies = { "tpope/vim-dadbod" },
    keys = {
        { "<leader>dd", function() require("dadbod-ui.api").toggle() end, desc = "Toggle DB tree" },
        { "<leader>da", function() require("dadbod-ui.api").add_connection() end, desc = "Add DB connection" },
    },
    opts = {
        use_nerd_fonts = true,
        picker = "telescope",
        drawer = { position = "right" },
    },
}
