vim.opt.showmode = false
vim.o.guifont = "JetBrainsMono Nerd Font:h14"
vim.g.neovide_hide_titlebar = true 
vim.g.neovide_position_animation_length = 0
vim.g.neovide_cursor_animation_length = 0.00
vim.g.neovide_cursor_trail_size = 0
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_scroll_animation_far_lines = 0
vim.g.neovide_scroll_animation_length = 0.00
vim.g.neovide_scale_factor = 1.3
vim.opt.termguicolors = true
require("settings")
require("config.lazy")        -- sets up lazy.nvim with only valid plugin specs
require("keymaps")
require("autocmds")
