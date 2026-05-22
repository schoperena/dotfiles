function Check-ImageMagick {
    if (Get-Command magick -ErrorAction SilentlyContinue) { return $true }
    else { return $false }
}

function Install-ImageMagick {
    Write-Host "ImageMagick no está instalado." -ForegroundColor Yellow
    $answer = Read-Host "¿Deseas instalar ImageMagick.Q16-HDRI ahora con winget? (S/N)"
    if ($answer.Trim().ToUpper() -eq 'S') {
        Write-Host "Iniciando instalación de ImageMagick.Q16-HDRI..." -ForegroundColor Cyan
        Start-Process -NoNewWindow -Wait -FilePath winget -ArgumentList "install","ImageMagick.Q16-HDRI"
        Write-Host "Instalación terminada. Verificando..." -ForegroundColor Green
        Start-Sleep -Seconds 3
        return Check-ImageMagick
    }
    else {
        Write-Host "No se instaló ImageMagick. Saliendo..." -ForegroundColor Red
        return $false
    }
}

function Add-ImageMagickToPath {
    if (Get-Command magick -ErrorAction SilentlyContinue) { return }
    $possiblePaths = @(
        "$env:ProgramFiles\ImageMagick-Q16-HDRI-*",
        "$env:ProgramFiles\ImageMagick-*",
        "$env:ProgramFiles(x86)\ImageMagick-Q16-HDRI-*",
        "$env:ProgramFiles(x86)\ImageMagick-*"
    )
    $magickExe = $null
    foreach ($basePath in $possiblePaths) {
        $folders = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $folders) {
            $exePath = Join-Path $folder.FullName "magick.exe"
            if (Test-Path $exePath) {
                $magickExe = $exePath
                break
            }
        }
        if ($magickExe) { break }
    }
    if (-not $magickExe) {
        Write-Host "No se encontró magick.exe en rutas típicas. Debes agregarlo manualmente al PATH." -ForegroundColor Red
        return
    }
    $magickFolder = Split-Path $magickExe
    if (-not ($env:PATH -split ';' | Where-Object { $_ -ieq $magickFolder })) {
        $env:PATH = "$magickFolder;$env:PATH"
        Write-Host "Se agregó ImageMagick al PATH de la sesión actual." -ForegroundColor Green
    }
}

function Show-Menu {
    param (
        [string]$title,
        [string[]]$options,
        [string[]]$defaultSelected = @()
    )

    Write-Host "`n=== $title ===`n"

    $selected = @{}
    for ($i = 0; $i -lt $options.Length; $i++) {
        $selected[$i] = $false
    }
    foreach ($d in $defaultSelected) {
        $idx = $options.IndexOf($d)
        if ($idx -ge 0) { $selected[$idx] = $true }
    }

    while ($true) {
        for ($i = 0; $i -lt $options.Length; $i++) {
            $mark = if ($selected[$i]) { '[x]' } else { '[ ]' }
            Write-Host "$($i+1). $mark $($options[$i])"
        }
        Write-Host "Selecciona el número para alternar selección, A para aceptar, Q para salir:"
        $input = Read-Host "Tu opción"
        if ($input -match '^[aA]$') {
            break
        }
        elseif ($input -match '^[qQ]$') {
            Write-Host "Saliendo..." -ForegroundColor Yellow
            exit
        }
        elseif ($input -match '^\d+$') {
            $num = [int]$input - 1
            if ($num -ge 0 -and $num -lt $options.Length) {
                $selected[$num] = -not $selected[$num]
            }
        }
        else {
            Write-Host "Entrada inválida. Intenta de nuevo." -ForegroundColor Red
        }
        Write-Host ""
    }

    $results = @()
    foreach ($k in $selected.Keys) {
        if ($selected[$k]) { $results += $options[$k] }
    }
    return $results
}

function Convert-Images {
    param(
        [string[]]$inputExts,
        [string]$outputExt
    )

    Write-Host "`nBuscando archivos con extensiones: $($inputExts -join ', ')" -ForegroundColor Cyan
    $files = Get-ChildItem -Recurse -File | Where-Object { $inputExts -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Host "No se encontraron archivos para convertir." -ForegroundColor Yellow
        return
    }

    $cpuCores = [Environment]::ProcessorCount
    Write-Host "Detectados $cpuCores núcleos CPU. Iniciando conversión en paralelo..." -ForegroundColor Green

    $files | ForEach-Object -Parallel {
        $destDir = Join-Path $_.DirectoryName "Convertidas"
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }
        $outputFile = Join-Path $destDir ($_.BaseName + ".$using:outputExt")
        Write-Host "Convirtiendo $($_.FullName) a $outputFile" -ForegroundColor Cyan
        magick "$($_.FullName)" "$outputFile"
    } -ThrottleLimit $cpuCores

    Write-Host "`nConversión completada. Las imágenes convertidas están en carpetas 'Convertidas'." -ForegroundColor Green
}

function Invoke-ImgConv {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "⚠️ Se recomienda usar PowerShell 7 o superior para mejor desempeño." -ForegroundColor Yellow
    }

    Write-Host "`n=== ImgConv - Conversor de imágenes con ImageMagick ===`n" -ForegroundColor Magenta

    if (-not (Check-ImageMagick)) {
        $installed = Install-ImageMagick
        if (-not $installed) {
            Write-Host "ImageMagick no disponible. Saliendo." -ForegroundColor Red
            return
        }
    }

    Add-ImageMagickToPath

    $availableInputFormats = @(".heic", ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tiff", ".tif", ".webp", ".ico", ".pdf")
    $availableOutputFormats = @("png", "jpg", "bmp", "gif", "tiff", "webp", "ico", "pdf")

    $selInput = Show-Menu -title "Selecciona los formatos de entrada" -options $availableInputFormats -defaultSelected @(".heic")
    if ($selInput.Count -eq 0) {
        Write-Host "No seleccionaste formatos de entrada. Saliendo." -ForegroundColor Red
        return
    }

    Write-Host "`nSelecciona el formato de salida:" -ForegroundColor Magenta
    for ($i=0; $i -lt $availableOutputFormats.Length; $i++) {
        Write-Host "$($i+1). $($availableOutputFormats[$i])"
    }
    while ($true) {
        $outSel = Read-Host "Número del formato de salida"
        if ($outSel -match '^\d+$' -and $outSel -ge 1 -and $outSel -le $availableOutputFormats.Length) {
            $outputExt = $availableOutputFormats[$outSel-1]
            break
        }
        Write-Host "Entrada inválida, intenta de nuevo." -ForegroundColor Red
    }

    Write-Host "`nConvertir archivos desde: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "De: $($selInput -join ', ')  → A: $outputExt" -ForegroundColor Cyan
    $ok = Read-Host "¿Confirmar? (S/N)"
    if ($ok.Trim().ToUpper() -ne 'S') {
        Write-Host "Operación cancelada." -ForegroundColor Yellow
        return
    }

    Convert-Images -inputExts $selInput -outputExt $outputExt
    Write-Host "`nGracias por usar ImgConv!" -ForegroundColor Magenta
}

Export-ModuleMember -Function Invoke-ImgConv
