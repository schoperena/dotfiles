#Requires -Version 7
<#
.SYNOPSIS
    Setup script for schoperena dotfiles.
    Run from the cloned repo: .\setup.ps1
    Or via one-liner: irm https://raw.githubusercontent.com/schoperena/dotfiles/main/setup.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

$isLocal  = $PSScriptRoot -ne ''
$repoBase = if ($isLocal) { $PSScriptRoot } else { 'https://raw.githubusercontent.com/schoperena/dotfiles/main' }
$psDir    = Split-Path $PROFILE   # e.g. ~\Documents\PowerShell
$modDir   = "$psDir\Modules"
$csDir    = "$psDir\CustomScripts"

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "    --  $msg" -ForegroundColor DarkGray }

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

function Download-Dir {
    param([string]$relDir, [string]$destDir)
    if ($isLocal) {
        $src = Join-Path $repoBase $relDir.Replace('/', '\')
        Copy-Item "$src\*" $destDir -Recurse -Force
    } else {
        Write-Host "      (remote directory download not supported via iex — clone the repo and re-run)" -ForegroundColor Yellow
    }
}

# ── Ensure target dirs exist ──────────────────────────────────────────────────
New-Item -ItemType Directory -Path $psDir,  $modDir, $csDir -Force | Out-Null

# ── 1. winget packages ────────────────────────────────────────────────────────
Write-Step "Installing winget packages"

$wingetPkgs = @(
    @{ id = 'JanDeDobbeleer.OhMyPosh';  name = 'oh-my-posh' }
    @{ id = 'ImageMagick.Q16-HDRI';      name = 'ImageMagick' }
)
foreach ($pkg in $wingetPkgs) {
    $installed = winget list --id $pkg.id --accept-source-agreements 2>&1 | Select-String $pkg.id
    if ($installed) {
        Write-Skip "$($pkg.name) already installed"
    } else {
        Write-Host "    Installing $($pkg.name)..." -ForegroundColor Yellow
        winget install --id $pkg.id -e --accept-package-agreements --accept-source-agreements
        Write-OK $pkg.name
    }
}

# ── 2. PowerShell modules (PSGallery) ─────────────────────────────────────────
Write-Step "Installing PowerShell modules from PSGallery"

$galleryModules = @('Terminal-Icons', 'ps2exe')
foreach ($mod in $galleryModules) {
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Skip "$mod already installed"
    } else {
        Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
        Write-OK $mod
    }
}

# ── 3. ImgConv (custom module) ────────────────────────────────────────────────
Write-Step "Installing ImgConv module"
$imgConvDest = "$modDir\ImgConv"
New-Item -ItemType Directory -Path $imgConvDest -Force | Out-Null
Copy-FromRepo 'Modules/ImgConv/ImgConv.psd1' "$imgConvDest\ImgConv.psd1"
Copy-FromRepo 'Modules/ImgConv/ImgConv.psm1' "$imgConvDest\ImgConv.psm1"
Write-OK "ImgConv -> $imgConvDest"

# ── 4. oh-my-posh themes ──────────────────────────────────────────────────────
Write-Step "Deploying oh-my-posh themes"
foreach ($theme in @('night-owl.omp.json', 'quick-term.omp.json', '.mytheme.omp.json')) {
    Copy-FromRepo "Documents/PowerShell/$theme" "$psDir\$theme"
    Write-OK $theme
}

# ── 5. PowerShell config ──────────────────────────────────────────────────────
Write-Step "Deploying powershell.config.json"
Copy-FromRepo 'Documents/PowerShell/powershell.config.json' "$psDir\powershell.config.json"
Write-OK "powershell.config.json"

# ── 6. Custom scripts ─────────────────────────────────────────────────────────
Write-Step "Deploying custom scripts to CustomScripts\"
Download-Dir 'Documents/PowerShell/CustomScripts' $csDir
Write-OK "CustomScripts -> $csDir"

# ── 7. PowerShell profile ─────────────────────────────────────────────────────
Write-Step "Deploying profile"
if (Test-Path $PROFILE) {
    $backup = "$PROFILE.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "    Backed up existing profile -> $backup" -ForegroundColor DarkYellow
}
Copy-FromRepo 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1' $PROFILE
Write-OK "Profile -> $PROFILE"

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "  Setup complete! Restart your terminal to apply." -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
