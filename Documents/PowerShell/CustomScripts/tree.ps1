param([string]$ruta)

if (-not $ruta) {
    Write-Host "Por favor proporciona una ruta."
    exit
}

if (-not (Test-Path $ruta)) {
    Write-Host "La ruta especificada no existe."
    exit
}

function MostrarArbolDirectorio($path, $level=0) {
    $indent = "  " * $level
    foreach ($item in Get-ChildItem $path -Force) {
        if ($item.PSIsContainer) {
            Write-Host "$indent+-- $($item.Name)"
            MostrarArbolDirectorio $item.FullName ($level + 1)
        } else {
            Write-Host "$indent|-- $($item.Name)"
        }
    }
}

MostrarArbolDirectorio $ruta