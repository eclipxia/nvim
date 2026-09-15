return {
  {
    "nvim-tree/nvim-tree.lua",
    -- <leader>e (bound in keymaps.lua) drives this via :NvimTreeToggle
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          side = "left",
          number = false,
          relativenumber = false,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
        git = {
          enable = true,
        },
      })
      -- <leader>e is bound in keymaps.lua (the same binding is what
      -- triggers this cmd-gated load in the first place)
    end,
  },
}

