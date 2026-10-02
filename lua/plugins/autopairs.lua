return {
  'windwp/nvim-autopairs',
  event = "InsertEnter", -- Only load when entering insert mode
  config = function()
    require('nvim-autopairs').setup({
      -- You can customize options here
      -- For example, to disable auto-closing for specific filetypes:
      -- disable_filetype = { "TelescopePrompt", "spectre_panel" },
      -- fast_wrap = {}, -- Enable fast_wrap feature
    })
    -- blink.cmp inserts brackets after accepting a function/method completion
    -- itself (completion.accept.auto_brackets), so no cmp-side bridge is needed.
  end
}
