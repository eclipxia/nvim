return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "LspAttach",
  priority = 1000, -- load before other LspAttach consumers touch diagnostics
  config = function()
    require("tiny-inline-diagnostic").setup({
      options = {
        multilines = { enabled = true },
        severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
      },
    })

    -- strchars() throws E976 on a line containing a NUL byte (binary files),
    -- which aborts every render. Treat that line as having no inlay hints.
    local extmarks = require("tiny-inline-diagnostic.extmarks")
    local count = extmarks.count_inlay_hints_characters
    extmarks.count_inlay_hints_characters = function(...)
      local ok, n = pcall(count, ...)
      return ok and n or 0
    end
  end,
}
