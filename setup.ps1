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
$psDir    = Split-Path $PROFILE       # ~\Documents\PowerShell
$modDir   = "$psDir\Modules"
$csDir    = "$psDir\CustomScripts"

# ─── Mapa de despliegue ───────────────────────────────────────────────────────
# Cada entrada: repo (ruta relativa en el repo) → machine (ruta absoluta destino)
$deployFiles = @(
    @{ repo = 'powershell/profile.ps1';              machine = $PROFILE }
    @{ repo = 'powershell/powershell.config.json';   machine = "$psDir\powershell.config.json" }
    @{ repo = 'powershell/themes/night-owl.omp.json'; machine = "$psDir\night-owl.omp.json" }
    @{ repo = 'powershell/themes/quick-term.omp.json'; machine = "$psDir\quick-term.omp.json" }
    @{ repo = 'powershell/themes/mytheme.omp.json';   machine = "$psDir\.mytheme.omp.json" }
)

# Scripts que van todos a CustomScripts\
$deployScripts = @(
    'BloquearAdobe.bat'
    'calc_digito_de_verificacion.py'
    'deblotear_TCL10L.ps1'
    'FormatearDisco.ps1'
    'MenuScripts.ps1'
    'New-SSHKey.ps1'
    'procesar_notebook.py'
    'renombrar_timelapse.ps1'
    'stirling-sch.ps1'
    'tree.ps1'
    'verify-checksum.ps1'
    'win11_rpd_patch.ps1'
)

# Módulos custom que van a Modules\<nombre>\
$deployModules = @(
    @{ name = 'ImgConv'; files = @('ImgConv.psd1', 'ImgConv.psm1') }
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "    --  $msg" -ForegroundColor DarkGray }
function Write-Warn { param([string]$msg) Write-Host "   !!! $msg" -ForegroundColor Yellow }

function Get-RepoFile {
    # Devuelve la ruta local (si isLocal) o descarga al temp y devuelve esa ruta
    param([string]$relPath)
    if ($isLocal) {
        return Join-Path $repoBase $relPath.Replace('/', '\')
    } else {
        $tmp  = Join-Path $env:TEMP ("dotfiles_" + ($relPath -replace '[/\\]', '_'))
        Invoke-WebRequest "$repoBase/$relPath" -OutFile $tmp -UseBasicParsing
        return $tmp
    }
}

function Deploy-File {
    param([string]$repoPath, [string]$machinePath)
    $src = Get-RepoFile $repoPath
    New-Item -ItemType Directory -Path (Split-Path $machinePath) -Force | Out-Null
    Copy-Item $src $machinePath -Force
    Write-OK "$repoPath  →  $machinePath"
}

function Install-WingetPkg {
    param([string]$Id, [string]$Name, [string]$Source = 'winget')
    $check = winget list --id $Id --accept-source-agreements 2>&1 | Select-String $Id
    if ($check) { Write-Skip "$Name ya instalado" ; return }
    Write-Host "    Instalando $Name..." -ForegroundColor Yellow
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements --source $Source
    Write-OK $Name
}

function Install-NpmPkg {
    param([string]$Pkg, [string]$Name)
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Write-Warn "npm no encontrado — instala Node.js primero."; return }
    $check = npm list -g --depth=0 2>$null | Select-String ([regex]::Escape($Pkg))
    if ($check) { Write-Skip "$Name ya instalado" ; return }
    Write-Host "    Instalando $Name via npm..." -ForegroundColor Yellow
    npm install -g $Pkg
    Write-OK $Name
}

# ─── Multi-select interactivo ─────────────────────────────────────────────────

function Show-MultiSelect {
    param([string]$Title, [array]$Items)

    $selected = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $false }

    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "  [numero] seleccionar/deseleccionar  |  A = todos  |  Enter = confirmar  |  Q = ninguno" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $mark  = if ($selected[$i]) { '[x]' } else { '[ ]' }
            $color = if ($selected[$i]) { 'Green' } else { 'White' }
            Write-Host "    [$($i + 1)] $mark  $($Items[$i].label)" -ForegroundColor $color
        }
        Write-Host ""
        $key = Read-Host "  Opcion"

        if ($key -eq '')          { break }
        if ($key -match '^[qQ]$') { for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $false }; break }
        if ($key -match '^[aA]$') { for ($i = 0; $i -lt $Items.Count; $i++) { $selected[$i] = $true  }; break }
        if ($key -match '^\d+$')  {
            $idx = [int]$key - 1
            if ($idx -ge 0 -and $idx -lt $Items.Count) { $selected[$idx] = -not $selected[$idx] }
        }
    }

    $result = @()
    for ($i = 0; $i -lt $Items.Count; $i++) { if ($selected[$i]) { $result += $Items[$i] } }
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
Start-Sleep -Seconds 1

$browserItems = @(
    @{ label = 'Google Chrome';   id = 'Google.Chrome';        type = 'winget' }
    @{ label = 'Brave';           id = 'Brave.Brave';           type = 'winget' }
    @{ label = 'Mozilla Firefox'; id = 'Mozilla.Firefox';       type = 'winget' }
    @{ label = 'LibreWolf';       id = 'LibreWolf.LibreWolf';   type = 'winget' }
)

$aiItems = @(
    @{ label = 'Claude Desktop (Anthropic)'; id = 'Anthropic.Claude';         type = 'winget' }
    @{ label = 'Claude Code (CLI)';          id = '@anthropic-ai/claude-code'; type = 'npm'    }
    @{ label = 'Codex CLI (OpenAI)';         id = '@openai/codex';             type = 'npm'    }
)

$selectedBrowsers = Show-MultiSelect -Title 'Navegadores — ¿Cuales instalar?' -Items $browserItems
$selectedAI       = Show-MultiSelect -Title 'Herramientas AI — ¿Cuales instalar?' -Items $aiItems

Clear-Host

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 2 — Instalar paquetes
# ═══════════════════════════════════════════════════════════════════════════════

# ── 2a. Dependencias de desarrollo (siempre) ──────────────────────────────────
Write-Step "Dependencias de desarrollo"
Install-WingetPkg 'Git.Git'                 'Git'
Install-WingetPkg 'GitHub.cli'              'GitHub CLI'
Install-WingetPkg 'JanDeDobbeleer.OhMyPosh' 'oh-my-posh'
Install-WingetPkg 'ImageMagick.Q16-HDRI'   'ImageMagick'

if ($selectedAI | Where-Object { $_.type -eq 'npm' }) {
    Install-WingetPkg 'OpenJS.NodeJS.LTS' 'Node.js LTS'
}

# ── 2b. Aplicaciones esenciales (siempre) ─────────────────────────────────────
Write-Step "Aplicaciones esenciales"
Install-WingetPkg 'VideoLAN.VLC'                'VLC'
Install-WingetPkg 'Microsoft.VisualStudioCode'  'Visual Studio Code'
Install-WingetPkg 'M2Team.NanaZip'              'NanaZip'
Install-WingetPkg '9NKSQGP7F2NH'               'WhatsApp' 'msstore'

# ── 2c. Navegadores seleccionados ─────────────────────────────────────────────
if ($selectedBrowsers.Count -gt 0) {
    Write-Step "Navegadores"
    foreach ($b in $selectedBrowsers) { Install-WingetPkg $b.id $b.label }
}

# ── 2d. Herramientas AI seleccionadas ─────────────────────────────────────────
if ($selectedAI.Count -gt 0) {
    Write-Step "Herramientas AI"
    foreach ($tool in $selectedAI) {
        if ($tool.type -eq 'winget') { Install-WingetPkg $tool.id $tool.label }
        elseif ($tool.type -eq 'npm') { Install-NpmPkg $tool.id $tool.label }
    }
}

# ── 2e. Módulos de PowerShell (PSGallery) ─────────────────────────────────────
Write-Step "Modulos de PowerShell (PSGallery)"
foreach ($mod in @('Terminal-Icons', 'ps2exe')) {
    if (Get-Module -ListAvailable -Name $mod) { Write-Skip "$mod ya instalado" ; continue }
    Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
    Write-OK $mod
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 3 — Desplegar archivos de configuración
# ═══════════════════════════════════════════════════════════════════════════════

Write-Step "Creando estructura de directorios"
New-Item -ItemType Directory -Path $psDir, $modDir, $csDir -Force | Out-Null
Write-OK $psDir

# ── 3a. Perfil, config y temas ────────────────────────────────────────────────
Write-Step "Perfil, config y temas"

# Backup del perfil existente si hay uno
if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "    Backup perfil anterior -> $backup" -ForegroundColor DarkYellow
}

foreach ($entry in $deployFiles) {
    Deploy-File $entry.repo $entry.machine
}

# ── 3b. Scripts → CustomScripts\ ─────────────────────────────────────────────
Write-Step "Scripts personales -> $csDir"
foreach ($script in $deployScripts) {
    Deploy-File "scripts/$script" "$csDir\$script"
}

# ── 3c. Módulos custom → Modules\<nombre>\ ────────────────────────────────────
Write-Step "Modulos custom -> $modDir"
foreach ($mod in $deployModules) {
    $dest = "$modDir\$($mod.name)"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    foreach ($file in $mod.files) {
        Deploy-File "modules/$($mod.name)/$file" "$dest\$file"
    }
}

# ── Fin ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║  Setup completo. Reinicia tu terminal.       ║" -ForegroundColor Green
Write-Host "  ║  Usa 'toolbox' para ver tus scripts.         ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
