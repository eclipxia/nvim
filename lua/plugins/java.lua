return {
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		cond = require("lang").any("java"),
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			local home = os.getenv("HOME")

			-- DAP/test support comes from Mason-installed bundles, kept separate
			-- from the manually-installed jdtls binary on PATH.
			local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
			local bundles = {}
			local debug_adapter = vim.fn.glob(
				mason_packages .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
			)
			if debug_adapter ~= "" then
				table.insert(bundles, debug_adapter)
			end
			-- list form (3rd arg true) returns {} when nothing matches, instead of
			-- the {""} that vim.split() would produce.
			vim.list_extend(bundles, vim.fn.glob(mason_packages .. "/java-test/extension/server/*.jar", false, true))

			-- Resolve installed SDKMAN JDKs by major version so point releases don't break the paths.
			local function sdk_jdk(major)
				local dirs = vim.fn.glob(home .. "/.sdkman/candidates/java/" .. major .. ".*", false, true)
				return dirs[#dirs]
			end

			-- Only register JDKs that are actually installed; a runtime with a nil
			-- path is invalid and confuses jdtls.
			local runtimes = {}
			for _, rt in ipairs({
				{ name = "JavaSE-17", major = "17" },
				{ name = "JavaSE-21", major = "21", default = true },
				{ name = "JavaSE-25", major = "25" },
			}) do
				local path = sdk_jdk(rt.major)
				if path then
					table.insert(runtimes, { name = rt.name, path = path, default = rt.default })
				end
			end

			-- Optional Lombok support: only enabled if a lombok.jar is available.
			local lombok = vim.fn.glob(mason_packages .. "/jdtls/lombok.jar")
			if lombok == "" then
				lombok = vim.fn.glob(home .. "/.local/share/jdtls/lombok.jar")
			end

			local root_markers = {
				"settings.gradle",
				"settings.gradle.kts",
				"build.gradle",
				"build.gradle.kts",
				"pom.xml",
				"mvnw",
				".git",
			}

			local settings = {
				java = {
					signatureHelp = { enabled = true },
					-- jdtls' equivalent of clangd's --function-arg-placeholders:
					-- without it, method completions never carry argument snippets.
					completion = {
						guessMethodArguments = true,
						-- static-import suggestions, e.g. Objects.requireNonNull
						favoriteStaticMembers = {
							"java.util.Objects.requireNonNull",
							"java.util.Objects.requireNonNullElse",
							"org.junit.jupiter.api.Assertions.*",
						},
						importOrder = { "java", "javax", "org", "com", "" },
					},
					-- fetch library sources/Javadoc so gd and K show real code
					eclipse = { downloadSources = true },
					maven = { downloadSources = true },
					sources = {
						organizeImports = {
							-- never collapse to wildcard imports
							starThreshold = 99,
							staticStarThreshold = 99,
						},
					},
					codeGeneration = { useBlocks = true },
					inlayHints = {
						parameterNames = { enabled = "all" },
					},
					format = {
						settings = {
							url = home .. "/.config/nvim/eclipse-formatter.xml",
							profile = "80col",
						},
					},
					import = {
						gradle = {
							enabled = true,
							wrapper = { enabled = true },
						},
					},
					imports = {
						gradle = {
							wrapper = {
								checksums = {
									{
										sha256 = "3b8a25775a69158b5ad2b1d17a80a88dc7b40a352a73eb27d06c612a7ce68e98",
										allowed = true,
									},
								},
							},
						},
					},
					configuration = {
						runtimes = runtimes,
					},
				},
			}

			local function on_attach(_, bufnr)
				local jdtls = require("jdtls")
				local set = function(mode, keys, cmd, desc)
					vim.keymap.set(mode, keys, cmd, { buffer = bufnr, desc = desc })
				end
				set("n", "K", vim.lsp.buf.hover, "Show documentation")
				set("n", "gd", vim.lsp.buf.definition, "Go to definition")
				set("n", "<leader>ca", vim.lsp.buf.code_action, "See available code actions")
				set("n", "<leader>rn", vim.lsp.buf.rename, "Smart rename")
				set("i", "<C-k>", vim.lsp.buf.signature_help, "Show signature help")
				set("n", "<leader>oi", jdtls.organize_imports, "Organize imports")
				set("n", "<leader>tc", jdtls.test_class, "Test class")
				set("n", "<leader>tm", jdtls.test_nearest_method, "Test nearest method")
				-- Refactorings (visual-mode ones act on the selection)
				set("n", "<leader>ev", jdtls.extract_variable, "Extract variable")
				set("x", "<leader>ev", function()
					jdtls.extract_variable(true)
				end, "Extract variable")
				set("n", "<leader>ec", jdtls.extract_constant, "Extract constant")
				set("x", "<leader>ec", function()
					jdtls.extract_constant(true)
				end, "Extract constant")
				set("x", "<leader>em", function()
					jdtls.extract_method(true)
				end, "Extract method")
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

				jdtls.setup_dap({ hotcodereplace = "auto" })
				require("jdtls.dap").setup_dap_main_class_configs()
			end

			-- Built per buffer so each Java file attaches to its own project root
			-- and gets its own jdtls workspace.
			local function make_config(bufnr)
				local root_dir = vim.fs.root(bufnr, root_markers)
					or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
				-- Key the workspace on the full root path so same-named folders in
				-- different places never share a jdtls workspace.
				local workspace_dir = home .. "/.cache/jdtls-workspace/" .. root_dir:gsub("[/\\:]", "_")

				-- Pick the JVM Gradle itself runs on, per project. Gradle 9+ can run on
				-- JDK 25 (needed by e.g. Fabric Loom builds that require Java 25);
				-- older wrappers (8.x) can't, so they stay on the default JDK 21.
				local project_settings = vim.deepcopy(settings)
				local props = root_dir .. "/gradle/wrapper/gradle-wrapper.properties"
				if vim.fn.filereadable(props) == 1 then
					local text = table.concat(vim.fn.readfile(props), "\n")
					local major = tonumber(text:match("gradle%-(%d+)[%.%d]*%-"))
					local jdk = major and major >= 9 and sdk_jdk("25") or sdk_jdk("21")
					if jdk then
						project_settings.java.import.gradle.java = { home = jdk }
					end
				end

				local cmd = {
					"jdtls",
					"-data",
					workspace_dir,
					"--jvm-arg=-Xmx4G",
					"--jvm-arg=-XX:+UseG1GC",
				}
				if lombok ~= "" then
					table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok)
				end

				return {
					cmd = cmd,
					root_dir = root_dir,
					-- jdtls.start_or_attach() bypasses vim.lsp.config("*", ...), so it
					-- never inherits blink's capabilities merge -- set them explicitly
					-- or jdtls never learns the client can expand snippet completions.
					capabilities = require("blink.cmp").get_lsp_capabilities(),
					settings = project_settings,
					init_options = {
						bundles = bundles,
						-- Needed for generate-constructor/toString/etc. and import
						-- code actions to work properly.
						extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
						-- Gradle import runs during initialize, before didChangeConfiguration
						-- delivers `settings`; pass them at init too so the wrapper checksum
						-- allowlist is already known when the import starts.
						settings = project_settings,
					},
					on_attach = on_attach,
				}
			end

			local function attach(bufnr)
				if vim.bo[bufnr].buftype ~= "" then
					return
				end
				require("jdtls").start_or_attach(make_config(bufnr))
			end

			-- This config runs lazily on the first `FileType java`, which has already
			-- fired for the current buffer, so attach it directly and cover every
			-- later Java buffer with the autocmd.
			attach(vim.api.nvim_get_current_buf())
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("UserJdtls", { clear = true }),
				pattern = "java",
				callback = function(args)
					attach(args.buf)
				end,
			})
		end,
	},
}
