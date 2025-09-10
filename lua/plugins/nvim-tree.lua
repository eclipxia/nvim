return {
  {
    "nvim-tree/nvim-tree.lua",
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

      -- ✅ Keybind: <leader>e to toggle the tree
      vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true })
    end,
  },
}

