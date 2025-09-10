return {
  'windwp/nvim-autopairs',
  event = "InsertEnter", -- Only load when entering insert mode
  config = function()
    require('nvim-autopairs').setup({
      -- You can customize options here
      -- For example, to disable auto-closing for specific filetypes:
      -- disable_filetype = { "TelescopePrompt", "spectre_panel" },
      -- To integrate with nvim-cmp:
      -- See https://github.com/windwp/nvim-autopairs#if-you-use-nvim-cmp
      -- if you're using nvim-cmp, you'll want to set up this integration.
      -- Example minimal integration:
      -- fast_wrap = {}, -- Enable fast_wrap feature
    })

    -- OPTIONAL: If you are using nvim-cmp for completion,
    -- you need to set up the integration for nvim-autopairs to play nicely.
    -- This ensures pairs are correctly handled when completions are active.
    local cmp_status_ok, cmp = pcall(require, "cmp")
    if cmp_status_ok then
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  end
}
