return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function terminal_status()
        if vim.bo.buftype == "terminal" then
          return "TERMINAL"
        end
        return ""
      end




      require("lualine").setup({
        options = {
          theme = "dracula",
          icons_enabled = true,
          -- component_separators = { left = "", right = "" },
          -- section_separators = { left = "", right = "" },
          -- globalstatus = true,
          -- component_separators = { left = "|", right = "|" },
          -- section_separators = { left = "|", right = "|" },
          component_separators = { left = " ", right = " " },
          section_separators = { left = " ", right = " " },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { {"filename", path = 3}, terminal_status },
					lualine_x = {
						{ 'datetime', style = '%H:%M' },
						'encoding',
						'fileformat',
						'filetype',
						'lsp_status',
					},
          lualine_y = { "progress" },
					lualine_z = { "location" },
        },
      })
    end,
  },
}

