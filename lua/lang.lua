-- Per-language profile gate. NVIM_LANG selects a profile (jvim/csvim/pvim
-- aliases set it); unset means plain `nvim`, which is the "everything"
-- profile except for plugins that opt out via `only`.
local active = vim.env.NVIM_LANG

local function has(l)
  return vim.tbl_contains(l, active)
end

return {
  -- inclusive: loads when NVIM_LANG is unset OR matches one of `...`
  any = function(...)
    local l = { ... }
    return function()
      return active == nil or has(l)
    end
  end,
  -- exclusive: loads ONLY when NVIM_LANG matches one of `...`
  only = function(...)
    local l = { ... }
    return function()
      return has(l)
    end
  end,
  active = active,
}
