return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "mason-org/mason.nvim",
      build = ":MasonUpdate",
      config = function()
        require("mason").setup()
      end,
    },
    {
      "mason-org/mason-lspconfig.nvim",
      config = function()
        local capabilities = vim.tbl_deep_extend(
          "force",
          {},
          vim.lsp.protocol.make_client_capabilities(),
          require("cmp_nvim_lsp").default_capabilities()
        )

        require("mason-lspconfig").setup({
          ensure_installed = { "lua_ls", "rust_analyzer", "pyright", "clangd" },
          handlers = {
            function(server)
              require("lspconfig")[server].setup { capabilities = capabilities }
            end,
            ["lua_ls"] = function()
              require("lspconfig").lua_ls.setup {
                capabilities = capabilities,
                settings = {
                  Lua = {
                    diagnostics = {
                      globals = { "vim", "it", "describe", "before_each", "after_each" },
                    },
                  },
                },
              }
            end,
          },
        })
      end,
    },
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "j-hui/fidget.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },

  config = function()
    -- Auto-install extra tools (not LSP servers)
    require("mason-tool-installer").setup({
      ensure_installed = { "flake8", "pylint", "stylua" },
      run_on_start = true,
    })

    -- Completion setup
    local cmp = require("cmp")
    local cmp_select = { behavior = cmp.SelectBehavior.Select }
    cmp.setup({
      snippet = {
        expand = function(args) require("luasnip").lsp_expand(args.body) end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        { name = "buffer" },
      }),
    })

    require("fidget").setup({})

    -- Diagnostics style
	vim.diagnostic.config({
		virtual_text = {
			severity = { min = vim.diagnostic.severity.WARN }, -- only WARN, ERROR
		},
		signs = {
			severity = { min = vim.diagnostic.severity.WARN },
		},
		underline = {
			severity = { min = vim.diagnostic.severity.WARN },
		},
		float = {
			severity = { min = vim.diagnostic.severity.WARN },
		},
	})
  end,
}
