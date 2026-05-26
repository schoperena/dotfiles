param (
    [string]$Ruta = (Get-Location).Path
)

# ─── Helpers de UI ───────────────────────────────────────────────────────────

function Titulo {
    param([string]$Texto)
    Write-Host ""
    Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Texto" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
}

function Separador { Write-Host "──────────────────────────────────────────" -ForegroundColor DarkGray }

# ─── Estado global ────────────────────────────────────────────────────────────

$script:criterios    = [ordered]@{}   # criterios activos: nombre → bloque lógico
$script:filtroExt    = "*"
$script:soloArchivos = $true

# ─── Obtener archivos del directorio ─────────────────────────────────────────

function Obtener-Archivos {
    $pattern = if ($script:filtroExt -eq "*") { "*" } else { "*.$($script:filtroExt)" }
    $items = Get-ChildItem -Path $Ruta -Filter $pattern |
             Where-Object { -not $_.PSIsContainer -or -not $script:soloArchivos } |
             Sort-Object Name
    return $items
}

# ─── Aplicar criterios al nombre base ────────────────────────────────────────

function Aplicar-Criterios {
    param([System.IO.FileSystemInfo]$archivo, [int]$indice, [int]$total)

    $nombre = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name)
    $ext    = $archivo.Extension   # incluye el punto

    foreach ($key in $script:criterios.Keys) {
        $c = $script:criterios[$key]
        switch ($c.tipo) {
            "reemplazar" {
                $nombre = $nombre -replace [regex]::Escape($c.buscar), $c.por
            }
            "prefijo" {
                $nombre = "$($c.valor)$nombre"
            }
            "sufijo" {
                $nombre = "$nombre$($c.valor)"
            }
            "numeracion" {
                $pad   = $c.digitos
                $sep   = $c.separador
                $pos   = $c.posicion   # "prefijo" o "sufijo"
                $num   = "{0:D$pad}" -f $indice
                if ($pos -eq "prefijo") { $nombre = "$num$sep$nombre" }
                else                    { $nombre = "$nombre$sep$num" }
            }
            "fecha" {
                $sep    = $c.separador
                $pos    = $c.posicion
                $fuente = $c.fuente    # "hoy","modificacion","creacion"
                $fmt    = $c.formato   # "yyyyMMdd","yyyy-MM-dd","ddMMyyyy"
                $fecha  = switch ($fuente) {
                    "hoy"         { Get-Date }
                    "modificacion" { $archivo.LastWriteTime }
                    "creacion"    { $archivo.CreationTime }
                }
                $fstr = $fecha.ToString($fmt)
                if ($pos -eq "prefijo") { $nombre = "$fstr$sep$nombre" }
                else                    { $nombre = "$nombre$sep$fstr" }
            }
            "mayusculas" {
                $nombre = $nombre.ToUpper()
            }
            "minusculas" {
                $nombre = $nombre.ToLower()
            }
            "titlecase" {
                $nombre = (Get-Culture).TextInfo.ToTitleCase($nombre.ToLower())
            }
            "limpiar" {
                # Quita caracteres no alfanuméricos (excepto guiones y underscores)
                $nombre = $nombre -replace '[^\w\-]', '_'
                $nombre = $nombre -replace '_+', '_'
                $nombre = $nombre.Trim('_')
            }
            "extension" {
                $ext = ".$($c.valor.TrimStart('.'))"
            }
        }
    }

    return "$nombre$ext"
}

# ─── Vista previa ─────────────────────────────────────────────────────────────

function Mostrar-Preview {
    param([array]$archivos)

    Titulo "VISTA PREVIA DE CAMBIOS"
    Write-Host ""

    if ($archivos.Count -eq 0) {
        Write-Warning "No hay archivos en '$Ruta' con el filtro aplicado."
        return @()
    }

    $cambios = @()
    $sinCambio = 0
    $maxLen = ($archivos | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum

    Write-Host ("{0,-$maxLen}   {1}" -f "NOMBRE ORIGINAL", "NOMBRE NUEVO") -ForegroundColor White
    Separador

    $i = 1
    foreach ($f in $archivos) {
        $nuevo = Aplicar-Criterios -archivo $f -indice $i -total $archivos.Count
        $igual = ($f.Name -eq $nuevo)

        if ($igual) {
            $sinCambio++
            Write-Host ("{0,-$maxLen}   (sin cambio)" -f $f.Name) -ForegroundColor DarkGray
        } else {
            Write-Host ("{0,-$maxLen}" -f $f.Name) -NoNewline -ForegroundColor Yellow
            Write-Host "   → " -NoNewline -ForegroundColor DarkGray
            Write-Host $nuevo -ForegroundColor Green
        }

        $cambios += [PSCustomObject]@{
            Archivo    = $f
            Original   = $f.Name
            Nuevo      = $nuevo
            HayCambio  = -not $igual
        }
        $i++
    }

    Separador
    $conCambio = ($cambios | Where-Object { $_.HayCambio }).Count
    Write-Host "Total: $($archivos.Count) archivos  |  " -NoNewline -ForegroundColor Gray
    Write-Host "$conCambio con cambios" -NoNewline -ForegroundColor Green
    Write-Host "  |  $sinCambio sin cambio" -ForegroundColor DarkGray

    return $cambios
}

# ─── Menú de criterios ────────────────────────────────────────────────────────

function Menu-Criterios {
    Titulo "CONFIGURAR CRITERIOS DE RENOMBRADO"

    $activos = if ($script:criterios.Count -gt 0) {
        "  Activos: " + ($script:criterios.Keys -join ", ")
    } else { "  (ninguno activo)" }

    Write-Host $activos -ForegroundColor Magenta
    Write-Host ""
    Write-Host "[1] Buscar y reemplazar texto"     -ForegroundColor White
    Write-Host "[2] Agregar prefijo"               -ForegroundColor White
    Write-Host "[3] Agregar sufijo"                -ForegroundColor White
    Write-Host "[4] Numeración secuencial"         -ForegroundColor White
    Write-Host "[5] Agregar fecha"                 -ForegroundColor White
    Write-Host "[6] Convertir a MAYÚSCULAS"        -ForegroundColor White
    Write-Host "[7] Convertir a minúsculas"        -ForegroundColor White
    Write-Host "[8] Convertir a Título (Title Case)" -ForegroundColor White
    Write-Host "[9] Limpiar caracteres especiales" -ForegroundColor White
    Write-Host "[10] Cambiar extensión"            -ForegroundColor White
    Write-Host "[11] Filtrar por extensión"        -ForegroundColor White
    Write-Host "[12] Quitar criterio"              -ForegroundColor Yellow
    Write-Host "[0] Volver (ver preview)"          -ForegroundColor Cyan
    Write-Host ""

    $op = Read-Host "Opción"
    switch ($op) {
        "1" {
            $buscar = Read-Host "Texto a buscar"
            $por    = Read-Host "Reemplazar por (dejar vacío para eliminar)"
            $script:criterios["reemplazar"] = @{ tipo="reemplazar"; buscar=$buscar; por=$por }
            Write-Host "✔ Criterio 'reemplazar' agregado." -ForegroundColor Green
        }
        "2" {
            $val = Read-Host "Prefijo a agregar"
            $script:criterios["prefijo"] = @{ tipo="prefijo"; valor=$val }
            Write-Host "✔ Criterio 'prefijo' agregado." -ForegroundColor Green
        }
        "3" {
            $val = Read-Host "Sufijo a agregar"
            $script:criterios["sufijo"] = @{ tipo="sufijo"; valor=$val }
            Write-Host "✔ Criterio 'sufijo' agregado." -ForegroundColor Green
        }
        "4" {
            $digits = Read-Host "Dígitos para el número (ej. 4 → 0001) [default: 3]"
            if (-not $digits) { $digits = "3" }
            $sep = Read-Host "Separador entre número y nombre (ej. _ o - o nada) [default: _]"
            if ($null -eq $sep -or $sep -eq "") { $sep = "_" }
            $pos = Read-Host "Posición: [P]refijo o [S]ufijo? [default: P]"
            $pos = if ($pos -match "^[sS]") { "sufijo" } else { "prefijo" }
            $script:criterios["numeracion"] = @{
                tipo      = "numeracion"
                digitos   = [int]$digits
                separador = $sep
                posicion  = $pos
            }
            Write-Host "✔ Criterio 'numeracion' agregado." -ForegroundColor Green
        }
        "5" {
            Write-Host "Fuente de fecha: [H]oy / [M]odificación / [C]reación [default: H]"
            $fuente = Read-Host "Fuente"
            $fuente = switch -Regex ($fuente) {
                "^[mM]" { "modificacion" }
                "^[cC]" { "creacion" }
                default { "hoy" }
            }
            Write-Host "Formato: [1] yyyyMMdd  [2] yyyy-MM-dd  [3] ddMMyyyy  [4] personalizado"
            $fmt = Read-Host "Formato [default: 1]"
            $fmt = switch ($fmt) {
                "2" { "yyyy-MM-dd" }
                "3" { "ddMMyyyy" }
                "4" { Read-Host "Escribe el formato (ej. yyyy_MM_dd)" }
                default { "yyyyMMdd" }
            }
            $sep = Read-Host "Separador entre fecha y nombre [default: _]"
            if ($null -eq $sep -or $sep -eq "") { $sep = "_" }
            $pos = Read-Host "Posición: [P]refijo o [S]ufijo? [default: P]"
            $pos = if ($pos -match "^[sS]") { "sufijo" } else { "prefijo" }
            $script:criterios["fecha"] = @{
                tipo      = "fecha"
                fuente    = $fuente
                formato   = $fmt
                separador = $sep
                posicion  = $pos
            }
            Write-Host "✔ Criterio 'fecha' agregado." -ForegroundColor Green
        }
        "6" {
            $script:criterios["mayusculas"] = @{ tipo="mayusculas" }
            $script:criterios.Remove("minusculas")
            $script:criterios.Remove("titlecase")
            Write-Host "✔ Criterio 'mayusculas' agregado." -ForegroundColor Green
        }
        "7" {
            $script:criterios["minusculas"] = @{ tipo="minusculas" }
            $script:criterios.Remove("mayusculas")
            $script:criterios.Remove("titlecase")
            Write-Host "✔ Criterio 'minusculas' agregado." -ForegroundColor Green
        }
        "8" {
            $script:criterios["titlecase"] = @{ tipo="titlecase" }
            $script:criterios.Remove("mayusculas")
            $script:criterios.Remove("minusculas")
            Write-Host "✔ Criterio 'titlecase' agregado." -ForegroundColor Green
        }
        "9" {
            $script:criterios["limpiar"] = @{ tipo="limpiar" }
            Write-Host "✔ Criterio 'limpiar' agregado." -ForegroundColor Green
        }
        "10" {
            $ext = Read-Host "Nueva extensión (sin punto, ej. txt)"
            $script:criterios["extension"] = @{ tipo="extension"; valor=$ext }
            Write-Host "✔ Criterio 'extension' agregado." -ForegroundColor Green
        }
        "11" {
            $script:filtroExt = Read-Host "Extensión a filtrar (ej. jpg, sin punto; o * para todos)"
            Write-Host "✔ Filtro de extensión: $($script:filtroExt)" -ForegroundColor Green
        }
        "12" {
            if ($script:criterios.Count -eq 0) {
                Write-Warning "No hay criterios activos."
            } else {
                Write-Host "Criterios activos: " -NoNewline
                Write-Host ($script:criterios.Keys -join ", ") -ForegroundColor Yellow
                $quitar = Read-Host "¿Cuál quitar?"
                if ($script:criterios.ContainsKey($quitar)) {
                    $script:criterios.Remove($quitar)
                    Write-Host "✔ Criterio '$quitar' eliminado." -ForegroundColor Green
                } else {
                    Write-Warning "Criterio '$quitar' no encontrado."
                }
            }
        }
        "0" { return }
        default { Write-Warning "Opción inválida." }
    }

    Start-Sleep -Milliseconds 700
    Menu-Criterios
}

# ─── Ejecutar renombrado ──────────────────────────────────────────────────────

function Ejecutar-Renombrado {
    param([array]$cambios)

    $aCambiar = $cambios | Where-Object { $_.HayCambio }

    if ($aCambiar.Count -eq 0) {
        Write-Warning "No hay cambios que aplicar."
        return $null
    }

    Write-Host ""
    Write-Host "Aplicando $($aCambiar.Count) cambios..." -ForegroundColor Cyan

    $historial = @()
    $errores   = 0

    foreach ($c in $aCambiar) {
        $destino = Join-Path (Split-Path $c.Archivo.FullName) $c.Nuevo
        try {
            Rename-Item -Path $c.Archivo.FullName -NewName $c.Nuevo -ErrorAction Stop
            $historial += [PSCustomObject]@{
                RutaOriginal = $c.Archivo.FullName
                RutaNueva    = $destino
                Original     = $c.Original
                Nuevo        = $c.Nuevo
            }
            Write-Host "  ✔ $($c.Original) → $($c.Nuevo)" -ForegroundColor Green
        }
        catch {
            $errores++
            Write-Warning "  ✘ Error renombrando '$($c.Original)': $_"
        }
    }

    Write-Host ""
    if ($errores -eq 0) {
        Write-Host "✅ $($historial.Count) archivos renombrados sin errores." -ForegroundColor Green
    } else {
        Write-Host "⚠️  $($historial.Count) renombrados, $errores con error." -ForegroundColor Yellow
    }

    return $historial
}

# ─── Revertir ─────────────────────────────────────────────────────────────────

function Revertir-Cambios {
    param([array]$historial)

    if (-not $historial -or $historial.Count -eq 0) {
        Write-Warning "No hay historial para revertir."
        return
    }

    Write-Host ""
    Write-Host "Revirtiendo $($historial.Count) cambios..." -ForegroundColor Yellow

    $ok     = 0
    $fallos = 0

    foreach ($h in $historial) {
        try {
            Rename-Item -Path $h.RutaNueva -NewName $h.Original -ErrorAction Stop
            $ok++
            Write-Host "  ↩ $($h.Nuevo) → $($h.Original)" -ForegroundColor Cyan
        }
        catch {
            $fallos++
            Write-Warning "  ✘ No se pudo revertir '$($h.Nuevo)': $_"
        }
    }

    Write-Host ""
    if ($fallos -eq 0) {
        Write-Host "✅ Reversión completada. $ok archivos restaurados." -ForegroundColor Green
    } else {
        Write-Host "⚠️  $ok revertidos, $fallos con error." -ForegroundColor Yellow
    }
}

# ─── FLUJO PRINCIPAL ──────────────────────────────────────────────────────────

Titulo "RENOMBRADO MASIVO"
Write-Host "  Directorio: $Ruta" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $Ruta)) {
    Write-Error "La ruta '$Ruta' no existe."
    exit 1
}

do {
    # Mostrar archivos originales antes de configurar criterios
    $archivos = Obtener-Archivos

    Titulo "ARCHIVOS EN DIRECTORIO"
    if ($archivos.Count -eq 0) {
        Write-Warning "No se encontraron archivos con filtro '$($script:filtroExt)'."
    } else {
        $archivos | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  Total: $($archivos.Count) archivos" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "[1] Configurar criterios" -ForegroundColor White
    Write-Host "[2] Ver preview de cambios" -ForegroundColor White
    Write-Host "[3] Aplicar renombrado" -ForegroundColor Yellow
    Write-Host "[Q] Salir" -ForegroundColor Red
    Write-Host ""

    $op = Read-Host "Opción"

    switch ($op.ToUpper()) {
        "1" { Menu-Criterios }
        "2" {
            if ($archivos.Count -gt 0) {
                Mostrar-Preview -archivos $archivos | Out-Null
                Write-Host ""
                Pause
            }
        }
        "3" {
            if ($script:criterios.Count -eq 0) {
                Write-Warning "Configura al menos un criterio antes de aplicar."
                Start-Sleep -Seconds 1
                break
            }

            $cambios = Mostrar-Preview -archivos $archivos

            Write-Host ""
            $confirmar = Read-Host "¿Deseas aplicar estos cambios? [S/N]"

            if ($confirmar -match "^[sS]") {
                $historial = Ejecutar-Renombrado -cambios $cambios

                if ($historial -and $historial.Count -gt 0) {
                    Write-Host ""
                    $decision = Read-Host "¿Todo correcto, o deseas revertir los cambios? [C = Confirmar / R = Revertir]"

                    if ($decision -match "^[rR]") {
                        Revertir-Cambios -historial $historial
                    } else {
                        Write-Host ""
                        Write-Host "✅ Cambios confirmados. El renombrado queda guardado." -ForegroundColor Green
                    }
                }

                Write-Host ""
                Pause
                break
            } else {
                Write-Host "Operación cancelada." -ForegroundColor DarkGray
                Start-Sleep -Milliseconds 700
            }
        }
        "Q" { break }
        default {
            Write-Warning "Opción inválida."
            Start-Sleep -Milliseconds 700
        }
    }

} while ($op.ToUpper() -ne "Q" -and $op.ToUpper() -ne "3")

Write-Host ""
Write-Host "Hasta luego." -ForegroundColor Cyan
