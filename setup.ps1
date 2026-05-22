#Requires -Version 7
<#
.SYNOPSIS
    Setup script for schoperena dotfiles.
    Run from the cloned repo:  .\setup.ps1
    Or via one-liner:          irm https://raw.githubusercontent.com/schoperena/dotfiles/main/setup.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

$isLocal  = $PSScriptRoot -ne ''
$repoBase = if ($isLocal) { $PSScriptRoot } else { 'https://raw.githubusercontent.com/schoperena/dotfiles/main' }
$psDir    = Split-Path $PROFILE
$modDir   = "$psDir\Modules"
$csDir    = "$psDir\CustomScripts"

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "    --  $msg" -ForegroundColor DarkGray }
function Write-Warn { param([string]$msg) Write-Host "   !!! $msg" -ForegroundColor Yellow }

function Copy-FromRepo {
    param([string]$relPath, [string]$dest)
    if ($isLocal) {
        $src = Join-Path $repoBase $relPath.Replace('/', '\')
        Copy-Item $src $dest -Force
    } else {
        $url = "$repoBase/$relPath"
        Invoke-WebRequest $url -OutFile $dest -UseBasicParsing
    }
}

function Deploy-RepoDir {
    param([string]$relDir, [string]$destDir)
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    if ($isLocal) {
        $src = Join-Path $repoBase $relDir.Replace('/', '\')
        Copy-Item "$src\*" $destDir -Recurse -Force
    } else {
        Write-Warn "Descarga de directorio no soportada via iex. Clona el repo y vuelve a ejecutar."
    }
}

function Install-WingetPkg {
    param([string]$Id, [string]$Name, [string]$Source = 'winget')
    $check = winget list --id $Id --accept-source-agreements 2>&1 | Select-String $Id
    if ($check) {
        Write-Skip "$Name ya instalado"
    } else {
        Write-Host "    Instalando $Name..." -ForegroundColor Yellow
        winget install --id $Id -e --accept-package-agreements --accept-source-agreements --source $Source
        Write-OK $Name
    }
}

function Install-NpmPkg {
    param([string]$Pkg, [string]$Name)
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warn "npm no encontrado. Instala Node.js primero."
        return
    }
    $installed = npm list -g --depth=0 2>$null | Select-String $Pkg
    if ($installed) {
        Write-Skip "$Name ya instalado"
    } else {
        Write-Host "    Instalando $Name via npm..." -ForegroundColor Yellow
        npm install -g $Pkg
        Write-OK $Name
    }
}

# ─── Multi-select interactivo ─────────────────────────────────────────────────

function Show-MultiSelect {
    param(
        [string]$Title,
        [array]$Items  # cada item: @{ label='...'; id='...' }
    )

    $selected = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $false }

    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "  Numero para seleccionar/deseleccionar | A = todos | Enter = confirmar | Q = ninguno" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $mark  = if ($selected[$i]) { '[x]' } else { '[ ]' }
            $color = if ($selected[$i]) { 'Green' } else { 'White' }
            Write-Host "    [$($i + 1)] $mark  $($Items[$i].label)" -ForegroundColor $color
        }

        Write-Host ""
        $key = Read-Host "  Opcion"

        if ($key -eq '')         { break }
        if ($key -match '^[qQ]$') { for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $false }; break }
        if ($key -match '^[aA]$') { for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $true  }; break }

        if ($key -match '^\d+$') {
            $idx = [int]$key - 1
            if ($idx -ge 0 -and $idx -lt $Items.Count) {
                $selected[$idx] = -not $selected[$idx]
            }
        }
    }

    $result = @()
    for ($i = 0; $i -lt $Items.Count; $i++) {
        if ($selected[$i]) { $result += $Items[$i] }
    }
    return $result
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 1 — Recopilar preferencias
# ═══════════════════════════════════════════════════════════════════════════════

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   schoperena dotfiles — Setup            ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Se instalarán dependencias esenciales y se pedirá tu selección" -ForegroundColor DarkGray
Write-Host "  para navegadores y herramientas AI." -ForegroundColor DarkGray
Start-Sleep -Seconds 2

$browserItems = @(
    @{ label = 'Google Chrome';  id = 'Google.Chrome' }
    @{ label = 'Brave';          id = 'Brave.Brave' }
    @{ label = 'Mozilla Firefox';id = 'Mozilla.Firefox' }
    @{ label = 'LibreWolf';      id = 'LibreWolf.LibreWolf' }
)

$aiItems = @(
    @{ label = 'Claude Desktop (Anthropic)';  id = 'Anthropic.Claude';    source = 'winget'; type = 'winget' }
    @{ label = 'Claude Code (CLI, npm)';      id = '@anthropic-ai/claude-code'; type = 'npm' }
    @{ label = 'Codex CLI (OpenAI, npm)';     id = '@openai/codex';            type = 'npm' }
)

$selectedBrowsers = Show-MultiSelect -Title 'Navegadores — ¿Cuales instalar?' -Items $browserItems
$selectedAI       = Show-MultiSelect -Title 'Herramientas AI — ¿Cuales instalar?' -Items $aiItems

Clear-Host

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 2 — Instalar
# ═══════════════════════════════════════════════════════════════════════════════

# ── 2a. Dependencias de desarrollo (siempre) ──────────────────────────────────
Write-Step "Dependencias de desarrollo"
Install-WingetPkg 'Git.Git'               'Git'
Install-WingetPkg 'GitHub.cli'            'GitHub CLI'
Install-WingetPkg 'JanDeDobbeleer.OhMyPosh' 'oh-my-posh'
Install-WingetPkg 'ImageMagick.Q16-HDRI' 'ImageMagick'

# Node.js solo si se seleccionó alguna herramienta npm
$needsNode = $selectedAI | Where-Object { $_.type -eq 'npm' }
if ($needsNode) {
    Install-WingetPkg 'OpenJS.NodeJS.LTS' 'Node.js LTS'
}

# ── 2b. Aplicaciones esenciales (siempre) ─────────────────────────────────────
Write-Step "Aplicaciones esenciales"
Install-WingetPkg 'VideoLAN.VLC'                 'VLC'
Install-WingetPkg 'Microsoft.VisualStudioCode'   'Visual Studio Code'
Install-WingetPkg 'M2Team.NanaZip'               'NanaZip'
Install-WingetPkg '9NKSQGP7F2NH'                 'WhatsApp' 'msstore'

# ── 2c. Navegadores seleccionados ─────────────────────────────────────────────
if ($selectedBrowsers.Count -gt 0) {
    Write-Step "Navegadores"
    foreach ($b in $selectedBrowsers) {
        Install-WingetPkg $b.id $b.label
    }
}

# ── 2d. Herramientas AI seleccionadas ─────────────────────────────────────────
if ($selectedAI.Count -gt 0) {
    Write-Step "Herramientas AI"
    foreach ($tool in $selectedAI) {
        if ($tool.type -eq 'winget') {
            Install-WingetPkg $tool.id $tool.label
        } elseif ($tool.type -eq 'npm') {
            Install-NpmPkg $tool.id $tool.label
        }
    }
}

# ── 2e. Modulos de PowerShell (PSGallery) ─────────────────────────────────────
Write-Step "Modulos de PowerShell"
foreach ($mod in @('Terminal-Icons', 'ps2exe')) {
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Skip "$mod ya instalado"
    } else {
        Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
        Write-OK $mod
    }
}

# ── 2f. ImgConv (modulo custom) ───────────────────────────────────────────────
Write-Step "Modulo ImgConv"
$imgConvDest = "$modDir\ImgConv"
New-Item -ItemType Directory -Path $imgConvDest -Force | Out-Null
Copy-FromRepo 'Modules/ImgConv/ImgConv.psd1' "$imgConvDest\ImgConv.psd1"
Copy-FromRepo 'Modules/ImgConv/ImgConv.psm1' "$imgConvDest\ImgConv.psm1"
Write-OK "ImgConv -> $imgConvDest"

# ── 2g. Temas oh-my-posh ──────────────────────────────────────────────────────
Write-Step "Temas oh-my-posh"
New-Item -ItemType Directory -Path $psDir -Force | Out-Null
foreach ($theme in @('night-owl.omp.json', 'quick-term.omp.json', '.mytheme.omp.json')) {
    Copy-FromRepo "Documents/PowerShell/$theme" "$psDir\$theme"
    Write-OK $theme
}

# ── 2h. Config de PowerShell ──────────────────────────────────────────────────
Write-Step "Configuracion de PowerShell"
Copy-FromRepo 'Documents/PowerShell/powershell.config.json' "$psDir\powershell.config.json"
Write-OK 'powershell.config.json'

# ── 2i. Scripts personales ────────────────────────────────────────────────────
Write-Step "Scripts personales (CustomScripts)"
Deploy-RepoDir 'Documents/PowerShell/CustomScripts' $csDir
Write-OK "CustomScripts -> $csDir"

# ── 2j. Perfil de PowerShell ──────────────────────────────────────────────────
Write-Step "Perfil de PowerShell"
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force | Out-Null
if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "    Backup -> $backup" -ForegroundColor DarkYellow
}
Copy-FromRepo 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1' $PROFILE
Write-OK "Perfil -> $PROFILE"

# ── Fin ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║  Setup completo. Reinicia tu terminal.       ║" -ForegroundColor Green
Write-Host "  ║  Usa 'toolbox' para ver tus scripts.         ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
