return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local dap_python = require("dap-python")

      -- Use the venv that has debugpy
      local py = vim.fn.expand("~/.venvs/debugpy313/bin/python")

      -- 1) Let dap-python set up default configs, pointing at your venv
      dap_python.setup(py)

      -- 2) Force the adapter to run with -Xfrozen_modules=off (silences adapter-side warning)
      dap.adapters.python = {
        type = "executable",
        command = py,
        args = { "-X", "frozen_modules=off", "-m", "debugpy.adapter" },
      }

      -- 3) Ensure the *debuggee* also gets the same flag or the env var
      --    (some setups emit the warning from the debuggee process).
      --    We define an explicit launch config that nvim-dap will use.
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file (no frozen modules)",
          program = "${file}",
          -- Pass interpreter + args to the debuggee (supported by debugpy):
          -- Either use pythonArgs via 'python' array, or the env var below.
          -- A) Interpreter args:
          python = { py, "-X", "frozen_modules=off" },
          -- B) Or, alternatively, uncomment this env var to silence the check:
          -- env = { PYDEVD_DISABLE_FILE_VALIDATION = "1" },
          justMyCode = false,
        },
      }

      require("dapui").setup({})
      require("nvim-dap-virtual-text").setup({ commented = true })

      -- Signs
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticSignWarn", linehl = "Visual", numhl = "DiagnosticSignWarn" })

      -- Auto-open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- Keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>db", function() dap.toggle_breakpoint() end, opts)
      vim.keymap.set("n", "<leader>dc", function() dap.continue() end, opts)
      vim.keymap.set("n", "<leader>do", function() dap.step_over() end, opts)
      vim.keymap.set("n", "<leader>di", function() dap.step_into() end, opts)
      vim.keymap.set("n", "<leader>dO", function() dap.step_out() end, opts)
      vim.keymap.set("n", "<leader>dq", function() dap.terminate() end, opts)
      vim.keymap.set("n", "<leader>du", function() dapui.toggle() end, opts)
    end,
  },
}
