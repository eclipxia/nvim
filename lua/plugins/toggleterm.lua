return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        direction = "horizontal",
        size = 8, -- smaller height
        open_mapping = [[<c-\>]],
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local bottom_term = Terminal:new({ direction = "horizontal", hidden = true, id = 1 })

      function _G.toggle_bottom_term()
        bottom_term:toggle()
      end
    end,
  },
}
