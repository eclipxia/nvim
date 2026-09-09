#!/usr/bin/env bash
# Bootstrap this Neovim config on a fresh macOS or Linux machine.
set -euo pipefail

REPO_URL="https://github.com/eclipxia/nvim.git"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. Install system dependencies
# ---------------------------------------------------------------------------
os="$(uname -s)"

if [[ "$os" == "Darwin" ]]; then
    log "Detected macOS"

    if ! command -v brew >/dev/null 2>&1; then
        log "Homebrew not found, installing it"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi

    log "Installing packages via Homebrew"
    brew install neovim git ripgrep fd node python3 luarocks

    if ! xcode-select -p >/dev/null 2>&1; then
        log "Installing Xcode Command Line Tools (needed for make/clang)"
        xcode-select --install || true
        warn "Finish the Xcode CLT install dialog, then re-run this script if it was just triggered."
    fi

    if ! command -v dotnet >/dev/null 2>&1; then
        log "Installing .NET SDK (needed by roslyn.nvim / csharp.lua)"
        brew install --cask dotnet-sdk
    fi

elif [[ "$os" == "Linux" ]]; then
    log "Detected Linux"

    if command -v apt-get >/dev/null 2>&1; then
        PM="apt"
        sudo apt-get update
        sudo apt-get install -y neovim git ripgrep fd-find python3 python3-pip \
            nodejs npm luarocks build-essential unzip curl dotnet-sdk-8.0
        # Debian/Ubuntu ship fd as `fdfind`; expose it as `fd` for plugins that expect that name
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            warn "Symlinked fdfind -> ~/.local/bin/fd. Make sure ~/.local/bin is on your PATH."
        fi

    elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"
        sudo dnf install -y neovim git ripgrep fd-find python3 python3-pip \
            nodejs npm luarocks make gcc gcc-c++ unzip curl dotnet-sdk-8.0

    elif command -v pacman >/dev/null 2>&1; then
        PM="pacman"
        sudo pacman -Sy --needed --noconfirm neovim git ripgrep fd python python-pip \
            nodejs npm luarocks base-devel unzip curl dotnet-sdk

    elif command -v zypper >/dev/null 2>&1; then
        PM="zypper"
        sudo zypper install -y neovim git ripgrep fd python3 python3-pip \
            nodejs npm luarocks make gcc gcc-c++ unzip curl dotnet-sdk-8_0

    else
        warn "No supported package manager found (apt/dnf/pacman/zypper)."
        warn "Install manually: neovim git ripgrep fd python3 node luarocks make gcc unzip curl dotnet-sdk"
        PM="none"
    fi
    log "Package manager used: $PM"

else
    warn "Unsupported OS: $os. This script supports macOS and Linux only."
    exit 1
fi

# lua/plugins/java.lua points jdtls at JDKs under ~/.sdkman/candidates/java,
# and jdtls itself isn't Mason-managed, so install both via SDKMAN.
if [[ ! -d "$HOME/.sdkman" ]]; then
    log "Installing SDKMAN (needed for jdtls + JDKs used by java.lua)"
    curl -s "https://get.sdkman.io" | bash
fi
# shellcheck disable=SC1090
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21-tem || true
sdk install jdtls || true
warn "java.lua also references JavaSE-17/25 SDKMAN candidates; install those with 'sdk install java 17-tem' / '25-tem' if you need them."

# ---------------------------------------------------------------------------
# 2. Clone (or update) the config
# ---------------------------------------------------------------------------
if [[ -d "$CONFIG_DIR/.git" ]]; then
    log "Existing nvim config found at $CONFIG_DIR, pulling latest"
    git -C "$CONFIG_DIR" pull --ff-only
elif [[ -e "$CONFIG_DIR" ]]; then
    backup="$CONFIG_DIR.bak.$(date +%s)"
    warn "$CONFIG_DIR exists but isn't this repo, moving it to $backup"
    mv "$CONFIG_DIR" "$backup"
    log "Cloning config to $CONFIG_DIR"
    git clone "$REPO_URL" "$CONFIG_DIR"
else
    log "Cloning config to $CONFIG_DIR"
    git clone "$REPO_URL" "$CONFIG_DIR"
fi

# ---------------------------------------------------------------------------
# 3. Sync plugins + tools headlessly
# ---------------------------------------------------------------------------
log "Syncing plugins with lazy.nvim"
nvim --headless "+Lazy! sync" +qa

log "Installing Mason-managed LSP servers/linters/formatters"
nvim --headless "+MasonToolsInstall" +qa || warn "MasonToolsInstall command not available yet, open nvim once manually to finish installs."

log "Done. Open nvim once interactively to let any remaining Mason installs finish."
