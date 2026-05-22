# MenuScripts.ps1
$RutaScripts = $PSScriptRoot

function Mostrar-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "    🚀 HUB DE SCRIPTS (Modo Rápido)       " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    $scripts = Get-ChildItem -Path $RutaScripts -Include *.ps1, *.py -Recurse -File | 
    Where-Object { $_.Name -ne "MenuScripts.ps1" }

    if ($scripts.Count -eq 0) {
        Write-Warning "No se encontraron scripts."
        return $null
    }

    $i = 1
    foreach ($script in $scripts) {
        $color = if ($script.Extension -eq ".py") { "Yellow" } else { "Green" }
        
        # Detectar si requiere admin (busca la etiqueta #Requires)
        $isAdmin = Get-Content $script.FullName -TotalCount 5 | Select-String "#Requires -RunAsAdministrator" -Quiet
        $adminBadge = if ($isAdmin) { "[ADMIN]" } else { "" }
        
        Write-Host "[$i] " -NoNewline -ForegroundColor White
        Write-Host "$($script.Name) " -NoNewline -ForegroundColor $color
        if ($isAdmin) { Write-Host $adminBadge -ForegroundColor Red -NoNewline }
        Write-Host ""
        $i++
    }
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Ejemplos de uso:" -ForegroundColor Gray
    Write-Host "  > 1                   (Ejecutar script 1 sin argumentos)" -ForegroundColor DarkGray
    Write-Host "  > 4 -Ruta 'C:\Mis Fotos'  (Ejecutar script 4 CON argumentos)" -ForegroundColor DarkGray
    Write-Host "------------------------------------------"
    
    return $scripts
}

do {
    $listaScripts = Mostrar-Menu
    if (-not $listaScripts) { break }

    # Leemos toda la línea de una vez
    $inputRaw = Read-Host "> "

    if ($inputRaw -match "^[qQ]$") { 
        Clear-Host
        break 
    }

    # Magia Regex: Separar el número (ID) del resto de argumentos
    if ($inputRaw -match "^(\d+)\s*(.*)$") {
        $id = $matches[1]
        $argumentosUsuario = $matches[2] # Esto captura todo lo que escribas después del número

        if ([int]$id -le $listaScripts.Count -and [int]$id -gt 0) {
            $scriptElegido = $listaScripts[[int]$id - 1]
            
            Write-Host "Lanzando: $($scriptElegido.Name)..." -ForegroundColor Magenta
            
            # --- LÓGICA DE ADMINISTRADOR ---
            # Verificamos si el script tiene la etiqueta #Requires -RunAsAdministrator
            $requiereAdmin = Get-Content $scriptElegido.FullName -TotalCount 10 | Select-String "# Requires -RunAsAdministrator" -Quiet

            if ($scriptElegido.Extension -eq ".ps1") {
                if ($requiereAdmin) {
                    Write-Warning "⚠️ Elevando permisos (Admin)..."
                    
                    # CORRECCIÓN: Agregamos "-ExecutionPolicy Bypass" a los argumentos
                    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$($scriptElegido.FullName)`"", $argumentosUsuario -Verb RunAs
                }
                else {
                    # Ejecución normal
                    Invoke-Expression "& '$($scriptElegido.FullName)' $argumentosUsuario"
                }
            }
            elseif ($scriptElegido.Extension -eq ".py") {
                # Python normal
                Invoke-Expression "python '$($scriptElegido.FullName)' $argumentosUsuario"
            }

            Write-Host "`n✅ Ejecución finalizada (Enter para volver al menú)" -ForegroundColor Green
            Pause
        }
        else {
            Write-Warning "Número inválido."
            Start-Sleep -Seconds 1
        }
    }
} while ($true)