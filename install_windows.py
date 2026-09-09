#!/usr/bin/env python3
"""Bootstrap this Neovim config on a fresh Windows machine."""
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO_URL = "https://github.com/eclipxia/nvim"
CONFIG_DIR = Path(os.environ["LOCALAPPDATA"]) / "nvim"


def log(msg):
    print(f"==> {msg}")


def warn(msg):
    print(f"!!  {msg}")


def run(cmd, check=True):
    return subprocess.run(cmd, shell=False, check=check)


# ---------------------------------------------------------------------------
# 1. Install system dependencies via winget
# ---------------------------------------------------------------------------
log("Installing packages via winget")
run([
    "winget", "install", "--silent",
    "--accept-source-agreements", "--accept-package-agreements",
    "Neovim.Neovim", "Git.Git", "BurntSushi.ripgrep.MSVC", "sharkdp.fd",
    "OpenJS.NodeJS.LTS", "Python.Python.3.12", "zig.zig",
    "Microsoft.DotNet.SDK.8", "EclipseAdoptium.Temurin.21.JDK",
])

# LuaRocks (needed for `luacheck`) isn't always reliably packaged on winget; try, then warn.
if run(["winget", "install", "--silent", "--accept-source-agreements",
        "--accept-package-agreements", "LuaRocks.LuaRocks"], check=False).returncode != 0:
    warn("Could not install LuaRocks via winget. Install it manually from https://luarocks.org/ if you want `luacheck` to work.")

# jdtls (needed by lua/plugins/java.lua) isn't Mason-managed and isn't on winget.
if shutil.which("jdtls") is None:
    warn("jdtls isn't packaged on winget. Install it manually (e.g. via scoop: 'scoop install jdtls') and make sure it's on PATH.")
warn(r"java.lua also expects JDKs under %USERPROFILE%\.sdkman\candidates\java (JavaSE-17/21/25) -- "
     "that layout is Linux/macOS-specific (SDKMAN). On Windows, update those runtime paths in "
     "lua/plugins/java.lua to point at your installed JDKs instead.")

# ---------------------------------------------------------------------------
# 2. Clone (or update) the config
# ---------------------------------------------------------------------------
if (CONFIG_DIR / ".git").exists():
    log(f"Existing nvim config found at {CONFIG_DIR}, pulling latest")
    run(["git", "-C", str(CONFIG_DIR), "pull", "--ff-only"])
elif CONFIG_DIR.exists():
    backup = CONFIG_DIR.with_name(CONFIG_DIR.name + ".bak." + datetime.now().strftime("%Y%m%d%H%M%S"))
    warn(f"{CONFIG_DIR} exists but isn't this repo, moving it to {backup}")
    CONFIG_DIR.rename(backup)
    log(f"Cloning config to {CONFIG_DIR}")
    run(["git", "clone", REPO_URL, str(CONFIG_DIR)])
else:
    log(f"Cloning config to {CONFIG_DIR}")
    run(["git", "clone", REPO_URL, str(CONFIG_DIR)])

# ---------------------------------------------------------------------------
# 3. Sync plugins + tools headlessly
# ---------------------------------------------------------------------------
log("Syncing plugins with lazy.nvim")
run(["nvim", "--headless", "+Lazy! sync", "+qa"])

log("Installing Mason-managed LSP servers/linters/formatters")
if run(["nvim", "--headless", "+MasonToolsInstall", "+qa"], check=False).returncode != 0:
    warn("MasonToolsInstall command not available yet, open nvim once manually to finish installs.")

# ---------------------------------------------------------------------------
# 4. Build telescope-fzf-native if lazy.nvim's own build step didn't run it
# ---------------------------------------------------------------------------
fzf_src = Path(os.environ["LOCALAPPDATA"]) / "nvim-data" / "lazy" / "telescope-fzf-native.nvim"
if (fzf_src / "src" / "fzf.c").exists() and not (fzf_src / "build" / "libfzf.dll").exists():
    log("Building telescope-fzf-native with zig cc")
    build_dir = fzf_src / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["zig", "cc", "-O3", "-Wall", "-Werror", "-fpic", "-std=gnu99", "-shared",
         "src/fzf.c", "-o", "build/libfzf.dll"],
        cwd=fzf_src, check=True,
    )
else:
    log("telescope-fzf-native already built (or handled by lazy.nvim's build step)")

log("Done. Open nvim once interactively to let any remaining Mason installs finish.")
