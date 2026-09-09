# Bootstrap this Neovim config on a fresh Windows machine.
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/eclipxia/nvim"
$ConfigDir = "$env:LOCALAPPDATA\nvim"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# 1. Install system dependencies via winget
# ---------------------------------------------------------------------------
Log "Installing packages via winget"
winget install --silent --accept-source-agreements --accept-package-agreements `
    Neovim.Neovim `
    Git.Git `
    BurntSushi.ripgrep.MSVC `
    sharkdp.fd `
    OpenJS.NodeJS.LTS `
    Python.Python.3.12 `
    zig.zig `
    Microsoft.DotNet.SDK.8 `
    EclipseAdoptium.Temurin.21.JDK

# LuaRocks (needed for `luacheck`) isn't always reliably packaged on winget; try, then warn.
try {
    winget install --silent --accept-source-agreements --accept-package-agreements LuaRocks.LuaRocks
} catch {
    Warn "Could not install LuaRocks via winget. Install it manually from https://luarocks.org/ if you want `luacheck` to work."
}

# jdtls (needed by lua/plugins/java.lua) isn't Mason-managed and isn't on winget.
if (-not (Get-Command jdtls -ErrorAction SilentlyContinue)) {
    Warn "jdtls isn't packaged on winget. Install it manually (e.g. via scoop: 'scoop install jdtls') and make sure it's on PATH."
}
Warn "java.lua also expects JDKs under `$HOME\.sdkman\candidates\java` (JavaSE-17/21/25) -- that layout is Linux/macOS-specific (SDKMAN). On Windows, update those runtime paths in lua/plugins/java.lua to point at your installed JDKs instead."

# ---------------------------------------------------------------------------
# 2. Clone (or update) the config
# ---------------------------------------------------------------------------
if (Test-Path "$ConfigDir\.git") {
    Log "Existing nvim config found at $ConfigDir, pulling latest"
    git -C $ConfigDir pull --ff-only
} elseif (Test-Path $ConfigDir) {
    $backup = "$ConfigDir.bak." + (Get-Date -Format "yyyyMMddHHmmss")
    Warn "$ConfigDir exists but isn't this repo, moving it to $backup"
    Move-Item $ConfigDir $backup
    Log "Cloning config to $ConfigDir"
    git clone $RepoUrl $ConfigDir
} else {
    Log "Cloning config to $ConfigDir"
    git clone $RepoUrl $ConfigDir
}

# ---------------------------------------------------------------------------
# 3. Sync plugins + tools headlessly
# ---------------------------------------------------------------------------
Log "Syncing plugins with lazy.nvim"
nvim --headless "+Lazy! sync" +qa

Log "Installing Mason-managed LSP servers/linters/formatters"
try {
    nvim --headless "+MasonToolsInstall" +qa
} catch {
    Warn "MasonToolsInstall command not available yet, open nvim once manually to finish installs."
}

# ---------------------------------------------------------------------------
# 4. Build telescope-fzf-native if lazy.nvim's own build step didn't run it
# ---------------------------------------------------------------------------
$fzfSrc = "$env:LOCALAPPDATA\nvim-data\lazy\telescope-fzf-native.nvim"
if ((Test-Path "$fzfSrc\src\fzf.c") -and -not (Test-Path "$fzfSrc\build\libfzf.dll")) {
    Log "Building telescope-fzf-native with zig cc"
    Push-Location $fzfSrc
    New-Item -ItemType Directory -Force -Path build | Out-Null
    zig cc -O3 -Wall -Werror -fpic -std=gnu99 -shared src/fzf.c -o build/libfzf.dll
    Pop-Location
} else {
    Log "telescope-fzf-native already built (or handled by lazy.nvim's build step)"
}

Log "Done. Open nvim once interactively to let any remaining Mason installs finish."
