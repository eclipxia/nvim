-- Create C# folders (namespaces) and types (class/interface/enum/record/
-- struct/exception) with a file-scoped namespace and a starter body.
--
-- Target directory, in order: the directory under the cursor in nvim-tree,
-- else the directory of the current buffer, else the working directory.
-- The namespace is <RootNamespace of the nearest .csproj> + the folder path
-- below that project, which is what `dotnet new` / Visual Studio would do.
local M = {}

local function trim_slash(p)
	return (p:gsub("/+$", ""))
end

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

-- Nearest .csproj at or above dir.
local function find_csproj(dir)
	return vim.fs.find(function(name)
		return name:match("%.csproj$") ~= nil
	end, { path = dir, upward = true, type = "file", limit = 1 })[1]
end

local function ident_segment(s)
	-- Folder names that aren't valid identifiers become underscores, like VS.
	return (s:gsub("[^%w_]", "_"):gsub("^(%d)", "_%1"))
end

-- Returns project dir, root namespace, whether ImplicitUsings is on.
local function project_info(csproj)
	local text = table.concat(vim.fn.readfile(csproj), "\n")
	local root_ns = text:match("<RootNamespace>%s*([^<%s]+)%s*</RootNamespace>")
		or ident_segment(vim.fn.fnamemodify(csproj, ":t:r"))
	local implicit = text:match("<ImplicitUsings>%s*(%a+)%s*</ImplicitUsings>")
	return vim.fs.dirname(csproj), root_ns, implicit ~= nil and implicit:lower() ~= "disable"
end

local function valid_ident(s)
	return s:match("^[%a_][%w_]*$") ~= nil
end

local function namespace_of(dir, project_dir, root_ns)
	if dir == project_dir then
		return root_ns
	end
	if dir:sub(1, #project_dir + 1) ~= project_dir .. "/" then
		return nil
	end
	local parts = { root_ns }
	for seg in dir:sub(#project_dir + 2):gmatch("[^/]+") do
		parts[#parts + 1] = ident_segment(seg)
	end
	return table.concat(parts, ".")
end

-- Resolve a (possibly dotted) input relative to the target dir.
-- Returns out_dir, namespace, name-or-nil, implicit_usings.
local function resolve(dir, input, wants_type)
	local csproj = find_csproj(dir)
	if not csproj then
		vim.notify("CsNew: no .csproj found at or above " .. dir, vim.log.levels.ERROR)
		return
	end
	local project_dir, root_ns, implicit = project_info(csproj)
	local ns = namespace_of(dir, project_dir, root_ns)
	if not ns then
		vim.notify("CsNew: " .. dir .. " is outside " .. project_dir, vim.log.levels.ERROR)
		return
	end

	local parts = vim.split(input, ".", { plain = true })
	for _, part in ipairs(parts) do
		if not valid_ident(part) then
			vim.notify("CsNew: '" .. part .. "' is not a valid C# identifier", vim.log.levels.ERROR)
			return
		end
	end
	local name
	if wants_type then
		name = table.remove(parts)
	end

	local out_dir = dir
	if #parts > 0 then
		out_dir = dir .. "/" .. table.concat(parts, "/")
		ns = ns .. "." .. table.concat(parts, ".")
	end
	return out_dir, ns, name, implicit
end

-- Braces on the same line, matching the K&R preference in your editorconfig.
local function body(kind, name)
	if kind == "record" then
		return ("public record %s();\n"):format(name)
	elseif kind == "exception" then
		return table.concat({
			("public class %s : Exception {"):format(name),
			("    public %s() {"):format(name),
			"    }",
			"",
			("    public %s(string message) : base(message) {"):format(name),
			"    }",
			"",
			("    public %s(string message, Exception innerException) : base(message, innerException) {"):format(
				name
			),
			"    }",
			"}",
			"",
		}, "\n")
	end
	return ("public %s %s {\n    \n}\n"):format(kind, name)
end

--- New folder (== new namespace): prompts for a dotted name relative to the target dir.
function M.new_folder()
	local dir = target_dir()
	vim.ui.input({ prompt = "New folder/namespace (e.g. Services.Http): " }, function(input)
		if not input or input == "" then
			return
		end
		local out_dir, ns = resolve(dir, input, false)
		if not out_dir then
			return
		end
		vim.fn.mkdir(out_dir, "p")
		vim.notify("Created folder for namespace " .. ns)
	end)
end

--- New type: prompts for a name (optionally prefixed by sub-folders) and kind.
function M.new_type(kind)
	local dir = target_dir()

	local function create(chosen)
		vim.ui.input({ prompt = "New " .. chosen .. " (Name or Sub.Name): " }, function(input)
			if not input or input == "" then
				return
			end
			local out_dir, ns, name, implicit = resolve(dir, input, true)
			if not out_dir then
				return
			end

			local path = out_dir .. "/" .. name .. ".cs"
			if vim.uv.fs_stat(path) then
				vim.notify("CsNew: " .. path .. " already exists", vim.log.levels.ERROR)
				return
			end
			vim.fn.mkdir(out_dir, "p")

			local lines = {}
			-- Exceptions need System; with ImplicitUsings it's already global.
			if chosen == "exception" and not implicit then
				vim.list_extend(lines, { "using System;", "" })
			end
			vim.list_extend(lines, { "namespace " .. ns .. ";", "" })
			vim.list_extend(lines, vim.split(body(chosen, name), "\n", { plain = true, trimempty = true }))
			vim.fn.writefile(lines, path)

			vim.cmd.edit(vim.fn.fnameescape(path))
			if chosen == "exception" then
				-- Already complete; stay in normal mode on the type line.
				vim.cmd("normal! gg")
				vim.fn.search("^public class")
				return
			elseif chosen == "record" then
				vim.cmd("normal! G$")
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
	vim.ui.select({ "class", "interface", "enum", "record", "struct", "exception" }, { prompt = "C# type:" }, function(choice)
		if choice then
			create(choice)
		end
	end)
end

M.target_dir = target_dir

return M
