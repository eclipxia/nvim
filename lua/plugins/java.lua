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

      -- DAP/test support comes from Mason-installed bundles, kept separate
      -- from the manually-installed jdtls binary on PATH.
      local mason_packages = vim.fn.stdpath('data') .. '/mason/packages'
      local bundles = {}
      local debug_adapter = vim.fn.glob(
        mason_packages .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
      )
      if debug_adapter ~= '' then
        table.insert(bundles, debug_adapter)
      end
      vim.list_extend(
        bundles,
        vim.split(vim.fn.glob(mason_packages .. '/java-test/extension/server/*.jar'), '\n')
      )

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
                { name = 'JavaSE-17', path = home .. '/.sdkman/candidates/java/17.0.19-tem' },
                { name = 'JavaSE-21', path = home .. '/.sdkman/candidates/java/current', default = true },
                { name = 'JavaSE-25', path = home .. '/.sdkman/candidates/java/25.0.3-tem' },
              },
            },
          },
        },
        init_options = {
          bundles = bundles,
        },
        on_attach = function(client, bufnr)
          local jdtls = require('jdtls')
          local set = function(mode, keys, cmd, desc)
            vim.keymap.set(mode, keys, cmd, { buffer = bufnr, desc = desc })
          end
          set('n', 'K', vim.lsp.buf.hover, 'Show documentation')
          set('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
          set('n', '<leader>ca', vim.lsp.buf.code_action, 'See available code actions')
          set('n', '<leader>rn', vim.lsp.buf.rename, 'Smart rename')
          set('i', '<C-k>', vim.lsp.buf.signature_help, 'Show signature help')
          set('n', '<leader>oi', jdtls.organize_imports, 'Organize imports')
          set('n', '<leader>tc', jdtls.test_class, 'Test class')
          set('n', '<leader>tm', jdtls.test_nearest_method, 'Test nearest method')

          jdtls.setup_dap({ hotcodereplace = 'auto' })
          require('jdtls.dap').setup_dap_main_class_configs()
        end,
      }

      require('jdtls').start_or_attach(config)
    end,
  },
}
