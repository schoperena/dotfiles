$_ProfileDir = Split-Path $PROFILE

# Oh my posh
oh-my-posh init pwsh --config "$_ProfileDir\night-owl.omp.json" | Invoke-Expression

# Iconos para los tipos de archivo en terminal
Import-Module -Name Terminal-Icons

# ImgConv: Conversor de imagenes con ImageMagick
Import-Module -Name ImgConv
Set-Alias ImgConv Invoke-ImgConv

# Lanzar hub de scripts personales
function toolbox {
    $lugarOriginal = Get-Location
    & "$_ProfileDir\CustomScripts\MenuScripts.ps1"
    Set-Location $lugarOriginal
}

# Fastfetch al abrir terminal (solo si esta instalado)
if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch }

# codeX — codex con sandbox danger-full-access (requiere: npm i -g @openai/codex)
if (Get-Command codex -ErrorAction SilentlyContinue) {
    function Invoke-CodexDangerFullAccess {
        $exe = (Get-Command codex -CommandType Application,ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1).Path
        if ($exe) { & $exe --sandbox danger-full-access @args }
        else { Write-Warning "No se encontro el ejecutable de 'codex'." }
    }
    Set-Alias codeX Invoke-CodexDangerFullAccess
}

# claudeX — claude code con --dangerously-skip-permissions (requiere: npm i -g @anthropic-ai/claude-code)
if (Get-Command claude -ErrorAction SilentlyContinue) {
    function Invoke-ClaudeDangerousPermissions {
        $exe = (Get-Command claude -CommandType Application,ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1).Path
        if ($exe) { & $exe --dangerously-skip-permissions @args }
        else { Write-Warning "No se encontro el ejecutable de 'claude'." }
    }
    Set-Alias claudeX Invoke-ClaudeDangerousPermissions
}
