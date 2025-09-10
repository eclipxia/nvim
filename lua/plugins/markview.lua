return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- Load markview BEFORE treesitter so its queries are available.
  dependencies = {
    {
      "OXY2DEV/markview.nvim",
      lazy = false,            -- per README: do NOT lazy-load
      priority = 49,           -- ensure it comes before treesitter
      config = function()
        local presets = require("markview.presets")
        require("markview").setup({
          preview = {
            -- markview renders these filetypes by default; extend as you like
            filetypes = { "md", "rmd", "quarto" },
            modes = { "n", "no", "c" },
            hybrid_modes = { "i" },        -- insert-mode hybrid editing
            icon_provider = "internal",    -- or "mini" / "devicons"
            -- control where the splitview opens when used
            splitview_winopts = { split = "right" },
            debounce = 50,
          },
          markdown = {
            -- Example visual presets (see wiki)
            headings = presets.headings.glow,
            -- tables = require("markview.presets").tables.rounded, -- optional
          },
        })

        -- Optional keymaps for convenience (buffer-local for markdown)
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "markdown", "rmd", "quarto" },
          callback = function(ev)
            local opts = { buffer = ev.buf, silent = true, noremap = true }
            vim.keymap.set("n", "<leader>mp", "<cmd>Markview toggle<cr>", opts)        -- preview on/off (buffer)
            vim.keymap.set("n", "<leader>mh", "<cmd>Markview hybridToggle<cr>", opts)  -- hybrid mode on/off (buffer)
          end,
        })
      end,
    },
  },
}
