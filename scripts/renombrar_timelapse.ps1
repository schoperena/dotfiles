param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$RutaObjetivo
)

# 1. Lista de extensiones de imagen soportadas (puedes agregar más si quieres)
$ExtensionesPermitidas = @('.jpg', '.jpeg', '.png', '.heic', '.webp', '.tiff', '.bmp', '.raw', '.dng')

# Validación de ruta
if (-not (Test-Path $RutaObjetivo)) {
    Write-Error "❌ Error: La ruta '$RutaObjetivo' no existe."
    exit
}

# 2. Obtener archivos, filtrar por extensión y ORDENAR
Write-Host "📂 Escaneando: $RutaObjetivo" -ForegroundColor Cyan

$archivos = Get-ChildItem -Path $RutaObjetivo -File | 
            Where-Object { $ExtensionesPermitidas -contains $_.Extension.ToLower() } | 
            Sort-Object Name

$total = $archivos.Count

if ($total -eq 0) {
    Write-Warning "⚠️ No se encontraron imágenes (JPG, PNG, HEIC, etc.) en esta carpeta."
    exit
}

Write-Host "📸 Se encontraron $total imágenes. Renombrando..." -ForegroundColor Yellow

# 3. Renombrado masivo manteniendo la extensión original
$i = 1
foreach ($archivo in $archivos) {
    # Detecta la extensión original del archivo actual
    $ext = $archivo.Extension 
    
    # Formato: 0001.extensión (ej: 0001.heic)
    $nuevoNombre = "{0:D4}$ext" -f $i
    $nuevoPath = Join-Path -Path $RutaObjetivo -ChildPath $nuevoNombre

    # Evitar errores si el archivo ya se llama así
    if ($archivo.Name -ne $nuevoNombre) {
        try {
            Rename-Item -Path $archivo.FullName -NewName $nuevoNombre -ErrorAction Stop
        }
        catch {
            Write-Warning "No se pudo renombrar $($archivo.Name). Puede que el destino ya exista."
        }
    }
    $i++
}

Write-Host "✅ Proceso completado. $total archivos organizados." -ForegroundColor Green