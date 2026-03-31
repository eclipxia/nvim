return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { 
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {},
  keys = {
    -- Search in the entire Project Root (Standard)
    { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find Todo comments (Project)" },
    
    -- Search ONLY in the directory of the current file
    { 
      "<F5>", 
      function()
        require("telescope.builtin").live_grep({
          search_dirs = { vim.fn.expand("%:p:h") },
          prompt_title = "TODOs in Current Dir",
          default_text = "TODO|FIX|FIXME", -- Manually filtering for todo keywords
        })
      end, 
      desc = "Find Todo comments (Current Dir)" 
    },

    -- Alternative version using the built-in TodoTelescope command with CWD
    { 
      "<leader>fC", 
      "<cmd>execute 'TodoTelescope cwd=' . expand('%:p:h')<cr>", 
      desc = "TodoTelescope in Current Dir" 
    },
  },
}
