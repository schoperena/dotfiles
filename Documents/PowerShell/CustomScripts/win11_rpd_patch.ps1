# =============================================
# Patch termsrv.dll - Sesiones RDP multiples
# Windows 10/11 (incluye 24H2)
#
# INSTRUCCIONES:
#   1. Abre PowerShell como Administrador
#   2. Ejecuta: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   3. Ejecuta: .\patch_termsrv.ps1
#
# Para revertir el parche: .\patch_termsrv.ps1 -Revertir
# =============================================

param(
    [switch]$Revertir
)

# =============================================
# Verificacion de privilegios
# =============================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host ""
    Write-Host " ERROR: Este script NO esta ejecutandose como Administrador." -ForegroundColor Red
    Write-Host ""
    Write-Host " Solucion:" -ForegroundColor Yellow
    Write-Host "   1. Cierra esta ventana" -ForegroundColor Yellow
    Write-Host "   2. Presiona Win + X" -ForegroundColor Yellow
    Write-Host "   3. Selecciona 'PowerShell (Administrador)'" -ForegroundColor Yellow
    Write-Host "   4. Ejecuta: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass" -ForegroundColor Yellow
    Write-Host "   5. Ejecuta: .\patch_termsrv.ps1" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

$dllPath    = "C:\Windows\System32\termsrv.dll"
$backupPath = "C:\Windows\System32\termsrv.dll.backup"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Patch termsrv.dll - Sesiones RDP multiples" -ForegroundColor Cyan
Write-Host "============================================"
Write-Host " Servidor: $env:COMPUTERNAME" -ForegroundColor White
Write-Host " Fecha:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Version del DLL
$version = (Get-Item $dllPath).VersionInfo.FileVersion
Write-Host " DLL:      $version" -ForegroundColor White
Write-Host ""

# =============================================
# MODO REVERTIR
# =============================================
if ($Revertir) {
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host " Modo: REVERTIR parche" -ForegroundColor Yellow
    Write-Host "============================================"

    if (-not (Test-Path $backupPath)) {
        Write-Host " ERROR: No se encontro backup en: $backupPath" -ForegroundColor Red
        Write-Host " No se puede revertir sin el archivo original." -ForegroundColor Red
        pause
        exit 1
    }

    Write-Host " Deteniendo servicio TermService..." -ForegroundColor White
    Stop-Service TermService -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host " Restaurando backup..." -ForegroundColor White
    takeown /f $dllPath | Out-Null
    icacls $dllPath /grant "Administrators:F" /q | Out-Null
    Copy-Item $backupPath $dllPath -Force

    Write-Host " Iniciando servicio TermService..." -ForegroundColor White
    Start-Service TermService -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host " termsrv.dll revertido al original." -ForegroundColor Green
    Write-Host ""
    pause
    exit 0
}

# =============================================
# Paso 1 - Backup
# =============================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Paso 1/5 - Creando backup..." -ForegroundColor Cyan
Write-Host "============================================"

if (Test-Path $backupPath) {
    Write-Host " Backup ya existe: $backupPath" -ForegroundColor Yellow
} else {
    Copy-Item $dllPath $backupPath -Force
    Write-Host " Backup creado: $backupPath" -ForegroundColor Green
}

# =============================================
# Paso 2 - Tomar propiedad y permisos
# =============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Paso 2/5 - Tomando propiedad del DLL..." -ForegroundColor Cyan
Write-Host "============================================"

takeown /f $dllPath | Out-Null
# Compatible español e inglés - dar permisos al usuario actual directamente
icacls $dllPath /grant "${env:USERDOMAIN}\${env:USERNAME}:F" /q | Out-Null
icacls $dllPath /grant "SYSTEM:F" /q | Out-Null
Write-Host " Permisos obtenidos." -ForegroundColor Green

# =============================================
# Paso 3 - Detener servicio
# =============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Paso 3/5 - Deteniendo servicio RDP..." -ForegroundColor Cyan
Write-Host "============================================"

Stop-Service TermService -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host " Servicio detenido." -ForegroundColor Green

# =============================================
# Paso 4 - Aplicar parche
# =============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Paso 4/5 - Aplicando parche..." -ForegroundColor Cyan
Write-Host "============================================"

$bytes = [System.IO.File]::ReadAllBytes($dllPath)

# Patrones conocidos
$patrones = @(
    @{
        Nombre  = "Win10/Win11 pre-24H2"
        Buscar  = [byte[]](0x39, 0x81, 0x3C, 0x06, 0x00, 0x00, 0x0F, 0x84)
        Parche  = [byte[]](0x39, 0x81, 0x3C, 0x06, 0x00, 0x00, 0x90, 0xE9)
        Revert  = [byte[]](0x39, 0x81, 0x3C, 0x06, 0x00, 0x00, 0x0F, 0x84)
    },
    @{
        Nombre  = "Win11 24H2+"
        Buscar  = [byte[]](0x8B, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3C, 0x06, 0x00, 0x00, 0x75)
        Parche  = [byte[]](0xB8, 0x00, 0x01, 0x00, 0x00, 0x89, 0x81, 0x38, 0x06, 0x00, 0x00, 0x90, 0xEB)
        Revert  = [byte[]](0x8B, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3C, 0x06, 0x00, 0x00, 0x75)
    }
)

$parcheAplicado = $false

foreach ($patron in $patrones) {
    $buscar = $patron.Buscar
    $parche = $patron.Parche
    $nombre = $patron.Nombre
    $encontrado = $false

    for ($i = 0; $i -le $bytes.Length - $buscar.Length; $i++) {
        $coincide = $true
        for ($j = 0; $j -lt $buscar.Length; $j++) {
            if ($bytes[$i + $j] -ne $buscar[$j]) {
                $coincide = $false
                break
            }
        }
        if ($coincide) {
            Write-Host " Patron encontrado: $nombre en offset 0x$($i.ToString('X'))" -ForegroundColor Green
            for ($j = 0; $j -lt $parche.Length; $j++) {
                $bytes[$i + $j] = $parche[$j]
            }
            $encontrado = $true
            $parcheAplicado = $true
            break
        }
    }

    # Verificar si ya esta parcheado
    if (-not $encontrado) {
        $yaParche = $patron.Parche
        for ($i = 0; $i -le $bytes.Length - $yaParche.Length; $i++) {
            $coincide = $true
            for ($j = 0; $j -lt $yaParche.Length; $j++) {
                if ($bytes[$i + $j] -ne $yaParche[$j]) {
                    $coincide = $false
                    break
                }
            }
            if ($coincide) {
                Write-Host " Ya estaba parcheado: $nombre" -ForegroundColor Yellow
                $parcheAplicado = $true
                break
            }
        }
    }
}

if (-not $parcheAplicado) {
    Write-Host ""
    Write-Host " ERROR: No se encontro ningun patron conocido en termsrv.dll." -ForegroundColor Red
    Write-Host " Esta version del DLL puede no estar soportada todavia." -ForegroundColor Red
    Write-Host " Version: $version" -ForegroundColor Red
    Write-Host ""
    Write-Host " Iniciando servicio RDP de nuevo sin cambios..." -ForegroundColor Yellow
    Start-Service TermService -ErrorAction SilentlyContinue
    pause
    exit 1
}

[System.IO.File]::WriteAllBytes($dllPath, $bytes)
Write-Host " Parche escrito en disco." -ForegroundColor Green

# =============================================
# Paso 5 - Reiniciar servicio
# =============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " Paso 5/5 - Reiniciando servicio RDP..." -ForegroundColor Cyan
Write-Host "============================================"

Start-Service TermService -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$estado = (Get-Service TermService).Status
Write-Host " TermService: $estado" -ForegroundColor Green

# =============================================
# Resultado final
# =============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " PARCHE APLICADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "============================================"
Write-Host " Servidor:  $env:COMPUTERNAME" -ForegroundColor White
Write-Host " DLL:       $version" -ForegroundColor White
Write-Host " Backup en: $backupPath" -ForegroundColor White
Write-Host ""
Write-Host " Ahora puedes tener multiples sesiones RDP simultaneas." -ForegroundColor Green
Write-Host ""
Write-Host " Para revertir: .\patch_termsrv.ps1 -Revertir" -ForegroundColor Yellow
Write-Host ""
pause