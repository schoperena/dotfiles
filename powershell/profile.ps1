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
