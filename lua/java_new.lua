-- Create Java packages and types (class/interface/enum/record) with a
-- package declaration and a starter body, IntelliJ "New > Java Class" style.
--
-- Target directory, in order: the directory under the cursor in nvim-tree,
-- else the directory of the current buffer, else the working directory.
-- The package is derived from the path after src/<set>/java.
local M = {}

local function trim_slash(p)
	return (p:gsub("/+$", ""))
end

-- Directory the new thing should be created in.
local function target_dir()
	if vim.bo.filetype == "NvimTree" then
		local ok, api = pcall(require, "nvim-tree.api")
		local node = ok and api.tree.get_node_under_cursor() or nil
		if node and node.absolute_path then
			return trim_slash(node.type == "directory" and node.absolute_path or vim.fs.dirname(node.absolute_path))
		end
	end
	local name = vim.api.nvim_buf_get_name(0)
	if name ~= "" then
		return trim_slash(vim.fs.dirname(name))
	end
	return trim_slash(vim.fn.getcwd())
end

-- Source root (.../src/<set>/java) containing dir, or the project's
-- src/main/java when dir is outside one (e.g. the project root).
local function source_root(dir)
	local root = (dir .. "/"):match("^(.*/src/[^/]+/java)/")
	if root then
		return root
	end
	local default = dir .. "/src/main/java"
	if vim.fn.isdirectory(default) == 1 then
		return default
	end
	local project = vim.fs.root(dir, { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml", ".git" })
	if project and vim.fn.isdirectory(project .. "/src/main/java") == 1 then
		return project .. "/src/main/java"
	end
end

-- Directory path inside the source root, e.g. "com/foo" -> "com.foo".
local function package_of(dir, root)
	if dir == root then
		return ""
	end
	if dir:sub(1, #root + 1) ~= root .. "/" then
		return nil
	end
	return (dir:sub(#root + 2):gsub("/", "."))
end

local function join_pkg(a, b)
	if a == "" then
		return b
	end
	if b == "" then
		return a
	end
	return a .. "." .. b
end

local function valid_ident(s)
	return s:match("^[%a_$][%w_$]*$") ~= nil
end

-- Resolve where a (possibly dotted) name goes relative to the target dir.
-- Returns root, package, simple-name-or-nil.
local function resolve(dir, input, wants_type)
	local root = source_root(dir)
	if not root then
		vim.notify("JavaNew: no src/<set>/java source root found from " .. dir, vim.log.levels.ERROR)
		return
	end
	local base = package_of(dir, root)
	if not base then
		vim.notify("JavaNew: " .. dir .. " is not inside " .. root, vim.log.levels.ERROR)
		return
	end

	local parts = vim.split(input, ".", { plain = true })
	for _, part in ipairs(parts) do
		if not valid_ident(part) then
			vim.notify("JavaNew: '" .. part .. "' is not a valid Java identifier", vim.log.levels.ERROR)
			return
		end
	end

	local name
	if wants_type then
		name = table.remove(parts)
	end
	return root, join_pkg(base, table.concat(parts, ".")), name
end

local function body(kind, name)
	if kind == "record" then
		return ("public record %s() {}\n"):format(name)
	end
	if kind == "exception" then
		-- Checked exception with the four standard constructors.
		return table.concat({
			("public class %s extends Exception {"):format(name),
			("    public %s() {"):format(name),
			"        super();",
			"    }",
			"",
			("    public %s(String message) {"):format(name),
			"        super(message);",
			"    }",
			"",
			("    public %s(String message, Throwable cause) {"):format(name),
			"        super(message, cause);",
			"    }",
			"",
			("    public %s(Throwable cause) {"):format(name),
			"        super(cause);",
			"    }",
			"}",
			"",
		}, "\n")
	end
	return ("public %s %s {\n    \n}\n"):format(kind, name)
end

--- New package: prompts for a dotted name relative to the target dir.
function M.new_package()
	local dir = target_dir()
	vim.ui.input({ prompt = "New package (e.g. util.io): " }, function(input)
		if not input or input == "" then
			return
		end
		local root, pkg = resolve(dir, input, false)
		if not root then
			return
		end
		vim.fn.mkdir(root .. "/" .. pkg:gsub("%.", "/"), "p")
		vim.notify("Created package " .. pkg)
	end)
end

--- New type: prompts for a name (optionally prefixed by sub-packages) and kind.
function M.new_type(kind)
	local dir = target_dir()

	local function create(chosen)
		vim.ui.input({ prompt = "New " .. chosen .. " (Name or sub.pkg.Name): " }, function(input)
			if not input or input == "" then
				return
			end
			local root, pkg, name = resolve(dir, input, true)
			if not root then
				return
			end

			local out_dir = root .. (pkg ~= "" and "/" .. pkg:gsub("%.", "/") or "")
			local path = out_dir .. "/" .. name .. ".java"
			if vim.uv.fs_stat(path) then
				vim.notify("JavaNew: " .. path .. " already exists", vim.log.levels.ERROR)
				return
			end
			vim.fn.mkdir(out_dir, "p")

			local lines = {}
			if pkg ~= "" then
				vim.list_extend(lines, { "package " .. pkg .. ";", "" })
			end
			vim.list_extend(lines, vim.split(body(chosen, name), "\n", { plain = true, trimempty = true }))
			vim.fn.writefile(lines, path)

			vim.cmd.edit(vim.fn.fnameescape(path))
			-- Land inside the body: the blank line in a class, the parens in a record.
			if chosen == "exception" then
				-- Already complete; just stay in normal mode on the class line.
				vim.cmd("normal! gg")
				vim.fn.search("^public class")
				return
			elseif chosen == "record" then
				vim.cmd("normal! $F)")
			else
				vim.cmd("normal! G")
				vim.cmd("normal! k$")
			end
			vim.cmd.startinsert({ bang = chosen ~= "record" })
		end)
	end

	if kind then
		return create(kind)
	end
	vim.ui.select({ "class", "interface", "enum", "record", "exception" }, { prompt = "Java type:" }, function(choice)
		if choice then
			create(choice)
		end
	end)
end

M.target_dir = target_dir

return M
