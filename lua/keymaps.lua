-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }

-- Toggle nvim-tree with <leader>e
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts)
vim.keymap.set("n", "<leader>bd", ":bd!<CR>", { desc = "Force close buffer" })
-- Close current window with <leader>q
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", opts)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
--move highlighted stuffs
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- Optional: delete to blackhole to avoid overwriting clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', opts)  -- Delete without affecting registers

-- Add more keymaps below as needed
-- Save current file with <leader>w
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { noremap = true, silent = true })

-- Quit current window with <leader>q
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { noremap = true, silent = true })

-- -- Yank to system clipboard
-- vim.keymap.set({ "n", "v" }, "y", '"+y', { noremap = true, desc = "Yank to clipboard" })
-- vim.keymap.set("n", "yy", '"+yy', { noremap = true, desc = "Yank line to clipboard" })
--
-- -- Paste from system clipboard
-- vim.keymap.set({ "n", "v" }, "p", '"+p', { noremap = true, desc = "Paste from clipboard" })
-- vim.keymap.set({ "n", "v" }, "P", '"+P', { noremap = true, desc = "Paste before from clipboard" })

-- Command line enhancements
-- vim.keymap.set("n", ":", "q:$a", { desc = "Command line with cursor at end" })
-- vim.keymap.set("v", ":", "q:$a", { desc = "Command line with cursor at end (visual)" })
vim.keymap.set("t", "<C-:>", "<C-\\><C-n>q:$a", { desc = "Exit terminal and enter command mode with cursor at end" })

vim.keymap.set("n", "<C-;>", ":", { desc = "Enter command mode" })
vim.keymap.set("v", "<C-;>", ":", { desc = "Enter command mode (visual)" })
vim.keymap.set("t", "<C-;>", "<C-\\><C-n>:", { desc = "Exit terminal and enter command mode" })

-- Buffer navigation
vim.keymap.set("n", "<C-M-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<C-M-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-M-k>", "<cmd>bp<CR>", { desc = "Buffer previous (alt)" })
vim.keymap.set("n", "<C-M-j>", "<cmd>bn<CR>", { desc = "Buffer next (alt)" })

vim.keymap.set("t", "<C-M-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer (terminal)" })
vim.keymap.set("t", "<C-M-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer (terminal)" })
vim.keymap.set("t", "<C-M-k>", "<cmd>bp<CR>", { desc = "Buffer previous (terminal)" })
vim.keymap.set("t", "<C-M-j>", "<cmd>bn<CR>", { desc = "Buffer next (terminal)" })

-- Move split positions
vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to left" })
vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to right" })
vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to top" })
vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to bottom" })

vim.keymap.set("t", "<C-S-h>", "<C-\\><C-n><C-w>H", { desc = "Move window to left (terminal)" })
vim.keymap.set("t", "<C-S-l>", "<C-\\><C-n><C-w>L", { desc = "Move window to right (terminal)" })
vim.keymap.set("t", "<C-S-k>", "<C-\\><C-n><C-w>K", { desc = "Move window to top (terminal)" })
vim.keymap.set("t", "<C-S-j>", "<C-\\><C-n><C-w>J", { desc = "Move window to bottom (terminal)" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Move to left split from terminal" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Move to below split from terminal" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Move to above split from terminal" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Move to right split from terminal" })
vim.keymap.set("n", "<leader>t", "<cmd>lua toggle_bottom_term()<CR>", { desc = "Toggle bottom terminal" })
