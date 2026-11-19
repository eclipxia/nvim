-- One keymap pair for Java and C#: picks the language from the current
-- buffer, then from the project around the target directory, then from the
-- NVIM_LANG profile, and forwards to java_new / cs_new.
local M = {}

local function has_csproj(dir)
	return #vim.fs.find(function(name)
		return name:match("%.csproj$") ~= nil
	end, { path = dir, upward = true, type = "file", limit = 1 }) > 0
end

local function has_jvm_build(dir)
	return vim.fs.root(dir, {
		"settings.gradle",
		"settings.gradle.kts",
		"build.gradle",
		"build.gradle.kts",
		"pom.xml",
	}) ~= nil
end

local function detect()
	local active = require("lang").active
	if active == "java" or active == "cs" then
		return active
	end
	local ft = vim.bo.filetype
	if ft == "java" or ft == "cs" then
		return ft
	end
	-- nvim-tree / other buffers: look at the project around the target dir.
	local dir = require("java_new").target_dir()
	local cs, java = has_csproj(dir), has_jvm_build(dir)
	if cs and not java then
		return "cs"
	elseif java and not cs then
		return "java"
	elseif cs and java then
		vim.notify("Both a .csproj and a Gradle/Maven build found; open a .java or .cs file first", vim.log.levels.WARN)
		return nil
	end
	vim.notify("No Java (Gradle/Maven) or C# (.csproj) project found here", vim.log.levels.WARN)
end

function M.new_file()
	local lang = detect()
	if lang == "cs" then
		require("cs_new").new_type()
	elseif lang == "java" then
		require("java_new").new_type()
	end
end

function M.new_dir()
	local lang = detect()
	if lang == "cs" then
		require("cs_new").new_folder()
	elseif lang == "java" then
		require("java_new").new_package()
	end
end

return M
