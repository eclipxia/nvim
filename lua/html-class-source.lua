--- blink.cmp source: complete CSS selectors from the project's HTML files.
--- Typing `.` in a css buffer offers every class used in `class="..."`,
--- typing `#` offers every `id="..."`.
---
--- Register it in lua/plugins/blink-cmp.lua (providers + per_filetype.css).

local M = {}

-- Seconds a scan result stays valid, so typing does not re-read every file.
local CACHE_TTL = 3

---@type table<string, { time: number, classes: string[], ids: string[] }>
local cache = {}

--- Create the source. Called by blink.cmp.
---@return table
function M.new()
	return setmetatable({}, { __index = M })
end

--- Only active in css-like buffers.
---@return boolean
function M:enabled()
	local ft = vim.bo.filetype
	return ft == "css" or ft == "scss" or ft == "less"
end

--- Characters that open the completion menu.
---@return string[]
function M:get_trigger_characters()
	return { ".", "#" }
end

--- Collect the class and id names used by every .html file under `root`.
---@param root string Project root directory.
---@return string[] classes, string[] ids
local function scan(root)
	local hit = cache[root]
	if hit and (os.time() - hit.time) < CACHE_TTL then
		return hit.classes, hit.ids
	end

	local classes, ids, seen_c, seen_i = {}, {}, {}, {}
	local files = vim.fs.find(function(name)
		return name:match("%.html?$") ~= nil
	end, {
		path = root,
		type = "file",
		limit = 200,
		-- skip dependency / vcs folders
		skip = function(dir)
			return dir == "node_modules" or dir == ".git"
		end,
	})

	for _, file in ipairs(files) do
		local fh = io.open(file, "r")
		if fh then
			local text = fh:read("*a")
			fh:close()
			-- class="a b c" (also single quotes)
			for list in text:gmatch("class%s*=%s*[\"']([^\"']*)[\"']") do
				for name in list:gmatch("[%w_%-]+") do
					if not seen_c[name] then
						seen_c[name] = true
						classes[#classes + 1] = name
					end
				end
			end
			-- id="x"
			for name in text:gmatch("[%s\"']id%s*=%s*[\"']([%w_%-]+)[\"']") do
				if not seen_i[name] then
					seen_i[name] = true
					ids[#ids + 1] = name
				end
			end
		end
	end

	table.sort(classes)
	table.sort(ids)
	cache[root] = { time = os.time(), classes = classes, ids = ids }
	return classes, ids
end

--- Return the completion items for the current cursor position.
---@param ctx table blink.cmp context.
---@param callback fun(response: table)
function M:get_completions(ctx, callback)
	local before = ctx.line:sub(1, ctx.cursor[2])
	local kind_char = before:match("([%.#])[%w_%-]*$")
	if not kind_char then
		callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
		return
	end

	local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
	local classes, ids = scan(root)
	local names = kind_char == "." and classes or ids
	local kind = vim.lsp.protocol.CompletionItemKind
	local item_kind = kind_char == "." and kind.Class or kind.Constant

	local items = {}
	for _, name in ipairs(names) do
		items[#items + 1] = {
			label = name,
			kind = item_kind,
			insertText = name,
			labelDetails = { description = "html" },
		}
	end

	callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return M
