return {
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      local home = os.getenv('HOME')
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      local workspace_dir = home .. '/.cache/jdtls-workspace/' .. project_name

      local config = {
        cmd = {
          'jdtls',
          '-data', workspace_dir,
          '--jvm-arg=-Xmx4G',
          '--jvm-arg=-XX:+UseG1GC',
        },
        root_dir = vim.fs.root(0, {
          'settings.gradle', 'settings.gradle.kts',
          'build.gradle', 'build.gradle.kts',
          'pom.xml', 'mvnw', '.git',
        }),
        settings = {
          java = {
            signatureHelp = { enabled = true },
            import = {
              gradle = {
                enabled = true,
                wrapper = { enabled = true },
              },
            },
            configuration = {
              runtimes = {
                { name = 'JavaSE-17', path = home .. '/.sdkman/candidates/java/17.0.x-tem' },
                { name = 'JavaSE-21', path = home .. '/.sdkman/candidates/java/21.0.x-tem', default = true },
                { name = 'JavaSE-25', path = home .. '/.sdkman/candidates/java/25.0.x-tem' },
              },
            },
          },
        },
        init_options = {
          bundles = {},
        },
        on_attach = function(client, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)
        end,
      }

      require('jdtls').start_or_attach(config)
    end,
  },
}
