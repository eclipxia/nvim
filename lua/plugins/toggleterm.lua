return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    -- <leader>t (below) is the only other entry point besides <c-\>, which
    -- toggleterm's own open_mapping registers lazily on load -- so keys is
    -- enough to cover both.
    keys = {
      { "<leader>t", function() require("toggleterm.terminal").Terminal:new({ direction = "horizontal", hidden = true, id = 1 }):toggle() end, desc = "Toggle bottom terminal" },
    },
    config = function()
      require("toggleterm").setup({
        direction = "horizontal",
        size = 8, -- smaller height
        open_mapping = [[<c-\>]],
      })
    end,
  },
}
