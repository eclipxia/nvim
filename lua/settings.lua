vim.opt.number = true            -- show absolute line number on the current line
vim.opt.relativenumber = true    -- show relative line numbers on other lines
vim.opt.virtualedit = "block"    -- allow virtual cursor only in visual-block mode, not normal mode
vim.opt.swapfile = false
vim.opt.textwidth = 110          -- was re-set to this on every BufEnter; set once
vim.opt.colorcolumn = "110"

-- Diagnostic noise gate, TypeScript buffers only: "you declared this and
-- haven't used it yet", a casing rule, a line-length rule, a complexity
-- threshold -- none of it is a defect. Every other language keeps its
-- diagnostics untouched; quiet those in their own project config if they
-- ever get noisy. Filtered here, in the one place both LSP and nvim-lint
-- funnel through.
local diagnostic_noise = {
    -- unused locals / params / imports / fields, in every tool's phrasing
    "unused",
    "never used",
    "not used",
    "never read",
    "not accessed",
    "dead[_ ]code",
    "assigned a value but never",
    "declared but",
    -- ts 2564: strictPropertyInitialization on class fields
    "has no initializer and is not definitely assigned",
    -- class ceremony
    "docstring",
    "javadoc",
    "too%-few%-public%-methods",
    "protected%-access",
    "must be private and have accessor",
    "missing a javadoc",
    "undocumented",
    "designed for extension",
    "utility classes should not have",
    "hides a field",
    "should be declared final",
    -- naming conventions: a linter's taste in casing, not a defect
    "invalid%-name",
    "naming convention",
    "does not match .*pattern",
    "camelcase",
    "pascalcase",
    "snake_case",
    "should start with",
    "name does not match",
    -- formatting: conform owns this, no need to also be nagged about it
    "line too long",
    "line%-too%-long",
    "line is longer than",
    "exceeds the maximum line length",
    "trailing whitespace",
    "trailing%-whitespace",
    "missing%-final%-newline",
    "no newline at end of file",
    "does not end with a newline",
    "expected indentation",
    "wrong indentation",
    "should be on the previous line",
    "should be separated from previous statement",
    "missing whitespace",
    "extra blank line",
    "missing semicolon",
    "quotes",
    "imports are not sorted",
    "import%-order",
    "should be sorted",
    -- complexity metrics: an arbitrary threshold, never a bug
    "too many",
    "too%-many",
    "too complex",
    "cyclomatic",
    "cognitive complexity",
    "is too long",
    "magic number",
    "duplicate%-code",
    -- style preferences dressed up as findings
    "consider using",
    "consider%-using",
    "prefer ",
    "prefer%-",
    "can be simplified",
    "simplify ",
    "unnecessary",
    "redundant",
    "expression body",
    "use implicit type",
    "readonly modifier",
    "can be made static",
    -- comment chores
    "todo",
    "fixme",
    "hack comment",
    -- spelling
    "unknown word",
    "possible spelling",
}

local function is_signal(d)
    local text = (tostring(d.code or "") .. " " .. (d.message or "")):lower()
    for _, pattern in ipairs(diagnostic_noise) do
        if text:find(pattern) then
            return false
        end
    end
    return true
end

local ts_filetypes = { typescript = true, typescriptreact = true }

-- Wrapping set() rather than vim.diagnostic.config's display handlers, so the
-- dropped ones are gone from :Telescope diagnostics and ]d too, not just from
-- the gutter.
local diagnostic_set = vim.diagnostic.set
vim.diagnostic.set = function(ns, bufnr, diagnostics, ...)
    if not ts_filetypes[vim.bo[bufnr].filetype] then
        return diagnostic_set(ns, bufnr, diagnostics, ...)
    end
    return diagnostic_set(ns, bufnr, vim.tbl_filter(is_signal, diagnostics or {}), ...)
end

-- Signature help as end-of-line virtual text on the cursor line (replaces
-- blink's floating window). Only shown while the cursor is inside a call.
local sig_ns = vim.api.nvim_create_namespace("cursorline_signature")
local function show_signature()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, sig_ns, 0, -1)
    if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/signatureHelp" }) == 0 then return end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local params = vim.lsp.util.make_position_params(0, "utf-16")
    vim.lsp.buf_request(buf, "textDocument/signatureHelp", params, function(err, res)
        vim.api.nvim_buf_clear_namespace(buf, sig_ns, 0, -1)
        if err or not res or not res.signatures or #res.signatures == 0 then return end
        if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_win_get_cursor(0)[1] - 1 ~= row then return end
        local sig = res.signatures[(res.activeSignature or 0) + 1]
        local chunks = { { "  ", "Normal" } }
        local p = sig.parameters and sig.parameters[(sig.activeParameter or res.activeParameter or 0) + 1]
        local l = p and p.label
        if type(l) == "table" then -- [start, end) offsets into sig.label
            chunks[#chunks + 1] = { sig.label:sub(1, l[1]), "LspInlayHint" }
            chunks[#chunks + 1] = { sig.label:sub(l[1] + 1, l[2]), "LspSignatureActiveParameter" }
            chunks[#chunks + 1] = { sig.label:sub(l[2] + 1), "LspInlayHint" }
        else
            chunks[#chunks + 1] = { sig.label, "LspInlayHint" }
        end
        pcall(vim.api.nvim_buf_set_extmark, buf, sig_ns, row, 0, { virt_text = chunks, virt_text_pos = "eol" })
    end)
end
vim.api.nvim_create_autocmd({ "CursorMovedI", "CursorMoved" }, { callback = show_signature })
vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function(a) vim.api.nvim_buf_clear_namespace(a.buf, sig_ns, 0, -1) end,
})
