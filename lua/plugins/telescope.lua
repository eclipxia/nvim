return {
  'nvim-telescope/telescope.nvim',
  branch = "master",
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required for Telescope
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make', -- For Linux/macOS
      config = function()
        require('telescope').load_extension('fzf')
      end,
    },
  },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-h>"] = "preview_scrolling_left",
            ["<C-l>"] = "preview_scrolling_right",
          },
          n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-h>"] = "preview_scrolling_left",
            ["<C-l>"] = "preview_scrolling_right",
          },
        },
      },
      pickers = {
        buffers = {
          mappings = {
            i = {
              ["d"] = actions.delete_buffer,
            },
            n = {
              ["d"] = actions.delete_buffer,
            },
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      }
    })

    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help Tags' })
		vim.keymap.set("n", "<leader>re", "<cmd>Telescope registers<CR>", { desc = "Telescope Registers" })
    vim.keymap.set('n', '<leader>fc', builtin.git_commits, { desc = 'Find files' })
  end,
}
