# ==============================================================================
# Script de Despliegue Automatizado: Stirling-PDF Cliente Windows
# Empresa: Santiago & Choperena Auditores
# ==============================================================================
# Ip servidor
$ServerURL = "http://100.126.32.94:8080" 

$DownloadFolder = "$env:TEMP\StirlingPDF_Install"
$MsiFileName = "Stirling-PDF-windows-x86_64.msi"
$MsiFilePath = Join-Path -Path $DownloadFolder -ChildPath $MsiFileName

# Crear carpeta temporal si no existe
if (-not (Test-Path -Path $DownloadFolder)) {
    New-Item -ItemType Directory -Path $DownloadFolder | Out-Null
}

# 2. Obtener la URL de descarga de la última versión desde la API de GitHub
Write-Host "Buscando la última versión de Stirling-PDF..." -ForegroundColor Cyan
$ApiUrl = "https://api.github.com/repos/Stirling-Tools/Stirling-PDF/releases/latest"
$Release = Invoke-RestMethod -Uri $ApiUrl

# Filtrar los archivos (assets) para encontrar el instalador MSI
$MsiAsset = $Release.assets | Where-Object { $_.name -eq $MsiFileName }

if (-not $MsiAsset) {
    Write-Host "Error: No se encontró el instalador MSI en la última versión." -ForegroundColor Red
    exit
}

$DownloadUrl = $MsiAsset.browser_download_url
Write-Host "Última versión encontrada: $($Release.tag_name)" -ForegroundColor Green

# 3. Descargar el archivo MSI
Write-Host "Descargando instalador... Esto puede tardar un momento." -ForegroundColor Cyan
Invoke-WebRequest -Uri $DownloadUrl -OutFile $MsiFilePath

if (-not (Test-Path $MsiFilePath)) {
    Write-Host "Error al descargar el archivo." -ForegroundColor Red
    exit
}
Write-Host "Descarga completada con éxito." -ForegroundColor Green

# 4. Instalar silenciosamente apuntando al servidor de la oficina
Write-Host "Iniciando la instalación. Conectando al servidor: $ServerURL" -ForegroundColor Yellow

$InstallArgs = @(
    "/i", "`"$MsiFilePath`"",
    "STIRLING_SERVER_URL=`"$ServerURL`"",
    "STIRLING_LOCK_CONNECTION=1", # Bloquea la URL en la app para evitar errores de usuario
    "/qb" # Interfaz básica: muestra barra de progreso pero no pide clics
)

# Ejecutar el instalador y esperar a que termine
$Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallArgs -Wait -PassThru

# 5. Validación final
if ($Process.ExitCode -eq 0) {
    Write-Host "¡Instalación completada exitosamente!" -ForegroundColor Green
    Write-Host "El equipo ya puede abrir Stirling-PDF desde el menú de inicio y colocar la clave." -ForegroundColor Green
} else {
    Write-Host "La instalación terminó con el código de error: $($Process.ExitCode)" -ForegroundColor Red
}

# Limpieza del instalador para liberar espacio
Remove-Item -Path $MsiFilePath -Force -ErrorAction SilentlyContinue