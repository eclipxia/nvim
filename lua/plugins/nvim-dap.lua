return {
  {
    "mfussenegger/nvim-dap",
    cond = require("lang").any("python", "cs", "c"),
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      { "mfussenegger/nvim-dap-python", lazy = true },
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<leader>xb", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>xc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>xo", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>xi", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>xO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>xq", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>xu", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
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

      -- C# (netcoredbg, installed via Mason)
      dap.adapters.coreclr = {
        type = "executable",
        command = vim.fn.exepath("netcoredbg"),
        args = { "--interpreter=vscode" },
      }
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch build (dotnet)",
          request = "launch",
          program = function()
            return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
        },
      }

      -- C/C++ (codelldb, installed via Mason)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.exepath("codelldb"),
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.cpp = {
        {
          type = "codelldb",
          name = "Launch executable",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp

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
    end,
  },
}
