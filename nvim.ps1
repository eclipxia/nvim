
winget install Neovim.Neovim GoLang.Go OpenJS.NodeJS zig.zig git.git --silent

git clone https://github.com/eclipxia/nvim $env:LOCALAPPDATA\nvim

nvim --headless "+Lazy! sync" +qa

cd "$env:LOCALAPPDATA\nvim-data"
if (Test-Path "src/fzf.c") {
    zig cc -O3 -Wall -Werror -fpic -std=gnu99 -shared src/fzf.c -o build/libfzf.dll
} else {
    Write-Host "Source file not found. Check your nvim directory structure." -ForegroundColor Red
}



