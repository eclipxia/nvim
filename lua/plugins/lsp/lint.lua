
return{
  "mfussenegger/nvim-lint",
  config = function()
    require("lint").linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      python = { "pylint" },
      lua = { "luacheck" },
    }
  end,
}
