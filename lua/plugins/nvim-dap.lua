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

      -- Use the venv that has debugpy (Windows venvs put the interpreter under Scripts\, not bin/)
      local py = vim.fn.has("win32") == 1
        and vim.fn.expand("~/.venvs/debugpy313/Scripts/python.exe")
        or vim.fn.expand("~/.venvs/debugpy313/bin/python")

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
      local set = function(keys, cmd, desc)
        vim.keymap.set("n", keys, cmd, { noremap = true, silent = true, desc = desc })
      end
      set("<leader>db", function() dap.toggle_breakpoint() end, "Toggle breakpoint")
      set("<leader>dc", function() dap.continue() end, "Continue")
      set("<leader>do", function() dap.step_over() end, "Step over")
      set("<leader>di", function() dap.step_into() end, "Step into")
      set("<leader>dO", function() dap.step_out() end, "Step out")
      set("<leader>dq", function() dap.terminate() end, "Terminate")
      set("<leader>du", function() dapui.toggle() end, "Toggle DAP UI")
    end,
  },
}
