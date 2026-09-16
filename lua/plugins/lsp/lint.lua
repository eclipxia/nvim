
return{
  "mfussenegger/nvim-lint",
  event = { "BufWritePost", "BufReadPost", "InsertLeave" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      python = { "pylint" },
      lua = { "luacheck" },
      java = { "checkstyle" },
    }

    -- The default pylint linter shells out to a bare "pylint" on PATH,
    -- which may resolve to a totally different Python install than the
    -- active venv (tmux/direnv) -- it then can't see venv-installed 3rd
    -- party packages and reports false import errors. Route it through
    -- the venv's own interpreter instead, so it shares site-packages
    -- with whatever pyright is actually using.
    local function venv_python()
        local bin = vim.fn.has("win32") == 1 and "Scripts/python.exe" or "bin/python"
        if vim.env.VIRTUAL_ENV then
            local candidate = vim.env.VIRTUAL_ENV .. "/" .. bin
            if vim.fn.executable(candidate) == 1 then
                return candidate
            end
        end
        local venv_dir = vim.fs.find({ ".venv", "venv", ".env", "env" }, {
            upward = true,
            path = vim.fn.expand("%:p:h"),
            type = "directory",
        })[1]
        if venv_dir then
            local candidate = venv_dir .. "/" .. bin
            if vim.fn.executable(candidate) == 1 then
                return candidate
            end
        end
        return "python3"
    end
    lint.linters.pylint.cmd = venv_python
    lint.linters.pylint.args = {
        "-m",
        "pylint",
        "-f",
        "json",
        "--from-stdin",
        function()
            return vim.api.nvim_buf_get_name(0)
        end,
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })

    -- This config() runs mid-dispatch of the very event that triggered the
    -- plugin's lazy-load (e.g. the first BufReadPost). lazy.nvim's autocmd
    -- replay only re-fires *grouped* autocmds after loading a plugin, and
    -- the one just registered above has no group, so it never sees that
    -- first occurrence -- the first buffer's initial lint would otherwise
    -- be silently skipped. Cover it with one direct call.
    require("lint").try_lint()
  end,
}
