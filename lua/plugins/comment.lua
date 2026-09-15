return {
  -- Comment.nvim with <Space>/ keymap
  {
    'numToStr/Comment.nvim',
    keys = {
      { '<leader>/', function() require('Comment.api').toggle.linewise.current() end, mode = 'n', desc = "Toggle comment line" },
      {
        '<leader>/',
        function()
          local esc = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
          vim.api.nvim_feedkeys(esc, 'nx', false)
          require('Comment.api').toggle.linewise(vim.fn.visualmode())
        end,
        mode = 'v',
        desc = "Toggle comment block",
      },
    },
    config = function()
      require('Comment').setup()
    end
  },
}
