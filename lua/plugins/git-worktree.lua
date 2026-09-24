return {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    cmd = { "Wnew" },
    keys = {
        { "<leader>gwl", function() require("telescope").extensions.git_worktree.git_worktrees() end, desc = "Git worktrees" },
        { "<leader>gwc", function() require("telescope").extensions.git_worktree.create_git_worktree() end, desc = "Create git worktree" },
    },
    config = function()
        require("git-worktree").setup()
        require("telescope").load_extension("git_worktree")

        -- git-worktree.nvim's own create_worktree has no base-branch param
        -- (new branches always fork from HEAD), so :Wnew shells out directly.
        vim.api.nvim_create_user_command("Wnew", function(opts)
            local branch, base = opts.fargs[1], opts.fargs[2]
            if not branch then
                vim.notify("Wnew: branch name required", vim.log.levels.ERROR)
                return
            end
            if not base then
                base = vim.system({ "git", "rev-parse", "--verify", "--quiet", "main" }, { text = true }):wait().code == 0
                    and "main" or "master"
            end
            local path = "../" .. branch
            local res = vim.system({ "git", "worktree", "add", "-b", branch, path, base }, { text = true }):wait()
            if res.code ~= 0 then
                vim.notify("Wnew: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
                return
            end
            local push = vim.system({ "git", "push", "--set-upstream", "origin", branch }, { text = true, cwd = path }):wait()
            if push.code ~= 0 then
                vim.notify("Wnew: push failed: " .. vim.trim(push.stderr or ""), vim.log.levels.WARN)
            end
            require("git-worktree").switch_worktree(path)
        end, { nargs = "+", desc = "Create a worktree for a new branch off main/master (or a given base)" })
    end,
}
