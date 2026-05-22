# Requires -RunAsAdministrator
# Forzar a la consola a usar UTF-8 para mostrar acentos y ñ correctamente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Este script necesita permisos de Administrador. Por favor, ejecútalo como Administrador."
    Pause
    Exit
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   HERRAMIENTA DE FORMATEO (CON ETIQUETA)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Listar Unidades (Filtrando el disco de sistema para seguridad)
Write-Host "Buscando unidades disponibles..." -ForegroundColor Yellow
$discos = Get-Disk | Where-Object { $_.IsSystem -eq $false -and $_.IsBoot -eq $false }

if (!$discos) {
    Write-Host "No se encontraron discos externos o secundarios disponibles." -ForegroundColor Red
    Pause
    Exit
}

$discos | Select-Object Number, FriendlyName, Size, OperationalStatus | Format-Table -AutoSize

# 2. Seleccionar Disco
$diskNumber = Read-Host "Introduce el NÚMERO del disco que quieres formatear (Ej: 1)"

if ($diskNumber -notin $discos.Number) {
    Write-Host "Error: Número de disco inválido o es el disco del sistema." -ForegroundColor Red
    Pause
    Exit
}

# 3. Seleccionar Formato
Write-Host ""
Write-Host "Selecciona el sistema de archivos:"
Write-Host "1. NTFS (Windows Predeterminado)"
Write-Host "2. exFAT (Compatible con Mac/Linux)"
Write-Host "3. FAT32 (Máx 32GB)"
$fsSelection = Read-Host "Opción (1-3)"

Switch ($fsSelection) {
    '1' { $fs = "NTFS" }
    '2' { $fs = "exFAT" }
    '3' { $fs = "FAT32" }
    Default { $fs = "NTFS"; Write-Host "Opción no válida, se usará NTFS por defecto." -ForegroundColor Yellow }
}

# 4. Asignar Etiqueta (Nombre) - NUEVO PASO
Write-Host ""
$etiqueta = Read-Host "Escribe el NOMBRE del disco (Presiona ENTER para dejarlo sin nombre)"

# 5. Confirmación de Seguridad
Write-Host ""
Write-Host "¡PELIGRO! Vas a borrar TODOS los datos del Disco $diskNumber." -ForegroundColor Red -BackgroundColor Black
if ($etiqueta -ne "") {
    Write-Host "Se formateará como $fs con el nombre '$etiqueta'" -ForegroundColor Yellow
} else {
    Write-Host "Se formateará como $fs SIN etiqueta" -ForegroundColor Yellow
}

$confirm = Read-Host "¿Estás seguro? Escribe 'SI' para continuar"

if ($confirm -ne 'SI') {
    Write-Host "Operación cancelada." -ForegroundColor Green
    Pause
    Exit
}

# 6. Ejecución
Try {
    Write-Host "1/3 Limpiando disco (Borrando particiones y datos OEM)..." -ForegroundColor Cyan
    # Se añade -RemoveOEM para eliminar particiones protegidas de Linux/balenaEtcher
    Clear-Disk -Number $diskNumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
    
    Write-Host "2/3 Inicializando y creando partición primaria..." -ForegroundColor Cyan
    # Usamos -PartitionStyle MBR para mayor compatibilidad con FAT32/USB antiguos, 
    # o GPT si prefieres mantener el estándar moderno.
    Initialize-Disk -Number $diskNumber -PartitionStyle GPT -ErrorAction SilentlyContinue
    
    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
    
    Write-Host "3/3 Formateando volumen..." -ForegroundColor Cyan
    Format-Volume -Partition $partition -FileSystem $fs -Confirm:$false -Force -NewFileSystemLabel $etiqueta
    
    Write-Host ""
    Write-Host "¡Proceso completado con éxito!" -ForegroundColor Green
}
Catch {
    Write-Host ""
    Write-Host "Ocurrió un error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Nota: Si el error persiste, intenta desconectar y volver a conectar el USB." -ForegroundColor Yellow
}

Pause