return {
    "NicholasMata/sqlserver.nvim",
    -- cond = only("sql") restricts loading (and the SQL Tools Service
    -- install it triggers) to the sqlvim profile (NVIM_LANG=sql); plain
    -- nvim/jvim/csvim/pvim never pay for it. ft is belt-and-suspenders so
    -- even inside that profile it stays lazy until a .sql buffer opens.
    cond = require("lang").only("sql"),
    ft = "sql",
    opts = {
        keymap_prefix = "<C-s>",
        lsp_settings = {
            intelliSense = {
                enableIntellisense = true,
                enableSuggestions = true,
                lowerCaseSuggestions = false,
                enableErrorChecking = true,
                enableQuickInfo = true,
            },
            query = {
                batchSeparator = "GO",
                displayBitAsNumber = true,
                arithAbort = true,
                concatNullYieldsNull = true,
                ansiDefaults = false,
                quotedIdentifier = true,
                ansiNullDefaultOn = true,
                ansiPadding = true,
                ansiWarnings = true,
                ansiNulls = true,
                transactionIsolationLevel = "READ UNCOMMITTED",
                deadlockPriority = "Normal",
            },
            format = {
                useBracketForIdentifiers = false,
                placeSelectStatementReferencesOnNewLine = true,
                keywordCasing = "Uppercase",
                datatypeCasing = "Uppercase",
                alignColumnDefinitionsInColumns = true,
            },
            piiLogging = false,
        },
    },
}
