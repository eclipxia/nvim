return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2", -- required for Harpoon v2
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon Add File" },
    { "<leader>m", function() local h = require("harpoon") h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon Menu" },
    { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon File 1" },
    { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon File 2" },
    { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon File 3" },
    { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon File 4" },
  },
  config = function()
    require("harpoon"):setup()
  end,
}
