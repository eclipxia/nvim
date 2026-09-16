return {
  'nvim-telescope/telescope.nvim',
  branch = "master",
  cmd = "Telescope",
  keys = {
    { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find files' },
    { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = 'Live Grep' },
    { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Buffers' },
    { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = 'Help Tags' },
    { '<leader>re', '<cmd>Telescope registers<CR>', desc = 'Telescope Registers' },
    { '<leader>fc', function() require('telescope.builtin').git_commits() end, desc = 'Git commits' },
    { '<leader>ws', function() require('telescope.builtin').lsp_workspace_symbols() end, desc = 'Workspace symbols' },
  },
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required for Telescope
		{
			'nvim-telescope/telescope-fzf-native.nvim',
			-- Check if we are on Windows and use Zig
			build = vim.fn.has("win32") == 1
				and "zig cc -O3 -shared src/fzf.c -o build/libfzf.dll"
				or "make",
			config = function()
				require('telescope').load_extension('fzf')
			end,
		},
	},
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')

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
  end,
}
