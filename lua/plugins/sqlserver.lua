return {
    "NicholasMata/sqlserver.nvim",
    -- cond = only("sql") restricts loading (and the SQL Tools Service
    -- install it triggers) to the sqlvim profile (NVIM_LANG=sql); plain
    -- nvim/jvim/csvim/pvim never pay for it. ft is belt-and-suspenders so
    -- even inside that profile it stays lazy until a .sql buffer opens.
    cond = require("lang").only("sql"),
    ft = "sql",
    opts = {
        keymap_prefix = "<leader>s",
    },
}
