vim.opt.number = true            -- show absolute line number on the current line
vim.opt.relativenumber = true    -- show relative line numbers on other lines
vim.opt.virtualedit = "block"    -- allow virtual cursor only in visual-block mode, not normal mode
vim.opt.swapfile = false
vim.opt.textwidth = 110          -- was re-set to this on every BufEnter; set once
vim.opt.colorcolumn = "110"
vim.diagnostic.config({ virtual_text = true })
