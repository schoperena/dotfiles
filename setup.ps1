<#
.SYNOPSIS
    Setup script for schoperena dotfiles.
    Compatible con Windows PowerShell 5.1 y PowerShell 7+.

    Desde el repo clonado:
        .\setup.ps1
    One-liner (sin necesidad de git):
        & ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/schoperena/dotfiles/main/setup.ps1')))
#>

$ErrorActionPreference = 'Stop'
$RepoUrl = 'https://raw.githubusercontent.com/schoperena/dotfiles/main'

# ─── Bootstrap: si corre en PS < 7, instalar PS7 y relanzar ─────────────────
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host ""
    Write-Host "  PowerShell $($PSVersionTable.PSVersion) detectado." -ForegroundColor Yellow
    Write-Host "  Instalando PowerShell 7 via winget..." -ForegroundColor Cyan
    Write-Host ""

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  winget no encontrado. Instala 'App Installer' desde la Microsoft Store." -ForegroundColor Red
        Read-Host "  Presiona Enter para salir"
        exit 1
    }

    winget install --id Microsoft.PowerShell --source winget -e `
        --accept-package-agreements --accept-source-agreements

    # Refrescar PATH en la sesion actual
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path    = "$machinePath;$userPath"

    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)
    $pwshExe = if ($pwsh) { $pwsh.Source } else { "$env:ProgramFiles\PowerShell\7\pwsh.exe" }

    if (-not (Test-Path $pwshExe)) {
        Write-Host ""
        Write-Host "  PowerShell 7 instalado. Reinicia la terminal y ejecuta el script de nuevo." -ForegroundColor Yellow
        Read-Host "  Presiona Enter para salir"
        exit 0
    }

    Write-Host ""
    Write-Host "  Relanzando con PowerShell 7..." -ForegroundColor Cyan

    if ($PSCommandPath) {
        & $pwshExe -File $PSCommandPath
    } else {
        & $pwshExe -Command "& ([scriptblock]::Create((irm '$RepoUrl/setup.ps1')))"
    }
    exit $LASTEXITCODE
}

# ─── Variables globales ───────────────────────────────────────────────────────
$isLocal  = $PSScriptRoot -ne ''
$repoBase = if ($isLocal) { $PSScriptRoot } else { $RepoUrl }
$psDir    = Split-Path $PROFILE       # ~\Documents\PowerShell
$modDir   = "$psDir\Modules"
$csDir    = "$psDir\CustomScripts"

# ─── Mapa de despliegue ───────────────────────────────────────────────────────
$deployFiles = @(
    @{ repo = 'powershell/profile.ps1';                machine = $PROFILE }
    @{ repo = 'powershell/powershell.config.json';     machine = "$psDir\powershell.config.json" }
    @{ repo = 'powershell/themes/night-owl.omp.json';  machine = "$psDir\night-owl.omp.json" }
    @{ repo = 'powershell/themes/quick-term.omp.json'; machine = "$psDir\quick-term.omp.json" }
    @{ repo = 'powershell/themes/mytheme.omp.json';    machine = "$psDir\.mytheme.omp.json" }
    @{ repo = 'fastfetch/config.jsonc';                machine = "$env:APPDATA\fastfetch\config.jsonc" }
)

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

$deployModules = @(
    @{ name = 'ImgConv'; files = @('ImgConv.psd1', 'ImgConv.psm1') }
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "    --  $msg" -ForegroundColor DarkGray }
function Write-Warn { param([string]$msg) Write-Host "   !!! $msg" -ForegroundColor Yellow }

function Get-RepoFile {
    param([string]$relPath)
    if ($isLocal) {
        return Join-Path $repoBase $relPath.Replace('/', '\')
    } else {
        $tmp = Join-Path $env:TEMP ("dotfiles_" + ($relPath -replace '[/\\]', '_'))
        Invoke-WebRequest "$repoBase/$relPath" -OutFile $tmp -UseBasicParsing
        return $tmp
    }
}

function Deploy-File {
    param([string]$repoPath, [string]$machinePath)
    $src = Get-RepoFile $repoPath
    New-Item -ItemType Directory -Path (Split-Path $machinePath) -Force | Out-Null
    Copy-Item $src $machinePath -Force
    Write-OK "$repoPath  ->  $machinePath"
}

function Install-WingetPkg {
    param([string]$Id, [string]$Name, [string]$Source = 'winget')
    $check = winget list --id $Id --accept-source-agreements 2>&1 | Select-String $Id
    if ($check) { Write-Skip "$Name ya instalado"; return }
    Write-Host "    Instalando $Name..." -ForegroundColor Yellow
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements --source $Source
    Write-OK $Name
}

function Install-NpmPkg {
    param([string]$Pkg, [string]$Name)
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warn "npm no encontrado — instala Node.js primero."
        return
    }
    $check = npm list -g --depth=0 2>$null | Select-String ([regex]::Escape($Pkg))
    if ($check) { Write-Skip "$Name ya instalado"; return }
    Write-Host "    Instalando $Name via npm..." -ForegroundColor Yellow
    npm install -g $Pkg
    Write-OK $Name
}

function Install-FiraCodeNerdFont {
    $userFontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $fontDest     = "$userFontsDir\FiraCodeNerdFont-Regular.ttf"

    if (Test-Path $fontDest) { Write-Skip "FiraCode Nerd Font Regular ya instalada"; return }

    Write-Host "    Descargando FiraCode Nerd Font..." -ForegroundColor Yellow
    $tmpZip = "$env:TEMP\FiraCode_NF.zip"
    $tmpDir = "$env:TEMP\FiraCode_NF"

    try {
        Invoke-WebRequest 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip' `
            -OutFile $tmpZip -UseBasicParsing
        Expand-Archive $tmpZip $tmpDir -Force
        New-Item -ItemType Directory $userFontsDir -Force | Out-Null

        $ttf = Get-ChildItem "$tmpDir\*.ttf" |
               Where-Object { $_.Name -like '*Regular*' } |
               Select-Object -First 1
        if (-not $ttf) { Write-Warn "No se encontro FiraCodeNerdFont-Regular.ttf en el zip"; return }

        Copy-Item $ttf.FullName $fontDest -Force

        # Registrar para el usuario actual (no requiere admin)
        $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        New-ItemProperty -Path $regPath -Name 'FiraCode Nerd Font Regular (TrueType)' `
            -Value $fontDest -PropertyType String -Force | Out-Null

        Write-OK "FiraCode Nerd Font Regular instalada"
    }
    catch { Write-Warn "Error instalando fuente: $_" }
    finally { Remove-Item $tmpZip, $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}

function Set-WindowsTerminalConfig {
    $wtPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    )
    $wtSettings = $wtPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $wtSettings) {
        Write-Warn "Windows Terminal no encontrado — instálalo desde la Microsoft Store."
        return
    }

    try {
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json -AsHashtable

        # ── FiraCode Nerd Font en todos los perfiles ──
        if (-not $json.ContainsKey('profiles'))                  { $json['profiles']                  = @{} }
        if (-not $json.profiles.ContainsKey('defaults'))         { $json.profiles['defaults']         = @{} }
        if (-not $json.profiles.defaults.ContainsKey('font'))    { $json.profiles.defaults['font']    = @{} }
        $json.profiles.defaults.font['face'] = 'FiraCode Nerd Font'

        # ── PowerShell 7 como perfil por defecto ──
        $ps7 = $json.profiles.list | Where-Object {
            ($_.ContainsKey('commandline') -and $_['commandline'] -like '*pwsh*') -or
            ($_.ContainsKey('source')      -and $_['source']      -like '*PowerShell*')
        } | Select-Object -First 1

        if ($ps7) {
            $json['defaultProfile'] = $ps7['guid']
            Write-OK "PowerShell 7 -> perfil por defecto en Windows Terminal"
        } else {
            Write-Warn "Perfil de PS7 no encontrado en WT — abre Windows Terminal una vez y vuelve a ejecutar el script."
        }

        $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8
        Write-OK "Windows Terminal -> FiraCode Nerd Font configurada"
    }
    catch { Write-Warn "Error configurando Windows Terminal: $_" }
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
    @{ label = 'Google Chrome';   id = 'Google.Chrome';      type = 'winget' }
    @{ label = 'Brave';           id = 'Brave.Brave';         type = 'winget' }
    @{ label = 'Mozilla Firefox'; id = 'Mozilla.Firefox';     type = 'winget' }
    @{ label = 'LibreWolf';       id = 'LibreWolf.LibreWolf'; type = 'winget' }
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

# ── 2a. PowerShell 7 ─────────────────────────────────────────────────────────
Write-Step "PowerShell 7"
Install-WingetPkg 'Microsoft.PowerShell' 'PowerShell 7'

# ── 2b. Dependencias de desarrollo ───────────────────────────────────────────
Write-Step "Dependencias de desarrollo"
Install-WingetPkg 'Git.Git'                  'Git'
Install-WingetPkg 'GitHub.cli'               'GitHub CLI'
Install-WingetPkg 'JanDeDobbeleer.OhMyPosh' 'oh-my-posh'
Install-WingetPkg 'ImageMagick.Q16-HDRI'    'ImageMagick'
Install-WingetPkg 'Fastfetch-cli.Fastfetch' 'fastfetch'

if ($selectedAI | Where-Object { $_.type -eq 'npm' }) {
    Install-WingetPkg 'OpenJS.NodeJS.LTS' 'Node.js LTS'
}

# ── 2c. FiraCode Nerd Font ────────────────────────────────────────────────────
Write-Step "FiraCode Nerd Font"
Install-FiraCodeNerdFont

# ── 2d. Aplicaciones esenciales ───────────────────────────────────────────────
Write-Step "Aplicaciones esenciales"
Install-WingetPkg 'VideoLAN.VLC'               'VLC'
Install-WingetPkg 'Microsoft.VisualStudioCode' 'Visual Studio Code'
Install-WingetPkg 'M2Team.NanaZip'             'NanaZip'
Install-WingetPkg '9NKSQGP7F2NH'              'WhatsApp' 'msstore'

# ── 2e. Navegadores seleccionados ─────────────────────────────────────────────
if ($selectedBrowsers.Count -gt 0) {
    Write-Step "Navegadores"
    foreach ($b in $selectedBrowsers) { Install-WingetPkg $b.id $b.label }
}

# ── 2f. Herramientas AI seleccionadas ─────────────────────────────────────────
if ($selectedAI.Count -gt 0) {
    Write-Step "Herramientas AI"
    foreach ($tool in $selectedAI) {
        if ($tool.type -eq 'winget') { Install-WingetPkg $tool.id $tool.label }
        elseif ($tool.type -eq 'npm') { Install-NpmPkg $tool.id $tool.label }
    }
}

# ── 2g. Modulos de PowerShell (PSGallery) ─────────────────────────────────────
Write-Step "Modulos de PowerShell (PSGallery)"
foreach ($mod in @('Terminal-Icons', 'ps2exe')) {
    if (Get-Module -ListAvailable -Name $mod) { Write-Skip "$mod ya instalado"; continue }
    Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
    Write-OK $mod
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 3 — Desplegar archivos de configuracion
# ═══════════════════════════════════════════════════════════════════════════════

Write-Step "Creando estructura de directorios"
New-Item -ItemType Directory -Path $psDir, $modDir, $csDir, "$env:APPDATA\fastfetch" -Force | Out-Null
Write-OK $psDir

# ── 3a. Perfil, config y temas ────────────────────────────────────────────────
Write-Step "Perfil, config y temas"

if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "    Backup perfil anterior -> $backup" -ForegroundColor DarkYellow
}

foreach ($entry in $deployFiles) {
    Deploy-File $entry.repo $entry.machine
}

# ── 3b. Scripts -> CustomScripts\ ────────────────────────────────────────────
Write-Step "Scripts personales -> $csDir"
foreach ($script in $deployScripts) {
    Deploy-File "scripts/$script" "$csDir\$script"
}

# ── 3c. Modulos custom -> Modules\<nombre>\ ───────────────────────────────────
Write-Step "Modulos custom -> $modDir"
foreach ($mod in $deployModules) {
    $dest = "$modDir\$($mod.name)"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    foreach ($file in $mod.files) {
        Deploy-File "Modules/$($mod.name)/$file" "$dest\$file"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PASO 4 — Configurar Windows Terminal
# ═══════════════════════════════════════════════════════════════════════════════

Write-Step "Windows Terminal"
Set-WindowsTerminalConfig

# ── Fin ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║  Setup completo. Reinicia Windows Terminal.          ║" -ForegroundColor Green
Write-Host "  ║  Usa 'toolbox' para ver tus scripts personales.      ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
