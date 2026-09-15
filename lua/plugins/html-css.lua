-- Bootstrap (or any plain CSS framework) class-name completion. No real LSP
-- knows those class names, so this runs as an in-process LSP that parses the
-- stylesheets the buffer <link>s to — CDN URLs included — and feeds them
-- through the existing nvim_lsp cmp source.
return {
    {
        "Jezda1337/nvim-html-css",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        ft = { "html", "htmldjango", "javascriptreact", "typescriptreact", "svelte", "vue", "php", "astro", "templ" },
        opts = {
            enable_on = { "html", "htmldjango", "jsx", "tsx", "svelte", "vue", "php", "astro", "templ" },
            -- handlers left empty: gd/K stay bound to the normal LSP maps.
            style_sheets = {
                -- Global fallbacks for buffers with no <link> (fragments,
                -- partials). Drop or extend as needed.
                "https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css",
            },
        },
    },
}
