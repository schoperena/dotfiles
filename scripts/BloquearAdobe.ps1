#Requires -RunAsAdministrator

$hostsPath = "$env:WINDIR\System32\drivers\etc\hosts"

$dominios = @(
    'genuine.adobe.com'
    'prod.adobegenuine.com'
    'cc-api-data.adobe.io'
    'lcs-cops.adobe.io'
    'adobe.io'
    'ic.adobe.io'
    'practivate.adobe.com'
    'activate.adobe.com'
    'ereg.adobe.com'
    'activate.wip3.adobe.com'
    'wip3.adobe.com'
    '3dns-3.adobe.com'
    '3dns-2.adobe.com'
    'adobe-dns.adobe.com'
    'adobe-dns-2.adobe.com'
    'adobe-dns-3.adobe.com'
    'ereg.wip3.adobe.com'
    'activate-sea.adobe.com'
    'wwis-dubc1-vip60.adobe.com'
    'activate-sjc0.adobe.com'
    'hl2rcv.adobe.com'
    'lm.licenses.adobe.com'
    'lmlicenses.wip4.adobe.com'
)

Write-Host ""
Write-Host "  Bloqueador de Adobe" -ForegroundColor Cyan
Write-Host ""

# ── 1. Hosts ──────────────────────────────────────────────────────────────────
Write-Host "  [1/2] Actualizando archivo hosts..." -ForegroundColor Yellow

Copy-Item $hostsPath "$hostsPath.bak" -Force

$hostsContent = Get-Content $hostsPath -Raw
$agregados = 0

foreach ($dominio in $dominios) {
    $entrada = "0.0.0.0 $dominio"
    if ($hostsContent -notmatch [regex]::Escape($entrada)) {
        Add-Content $hostsPath "`r`n$entrada" -Encoding ASCII
        Write-Host "      Bloqueado: $dominio" -ForegroundColor Green
        $agregados++
    }
}

if ($agregados -eq 0) {
    Write-Host "      Todos los dominios ya estaban bloqueados." -ForegroundColor DarkGray
}

ipconfig /flushdns | Out-Null
Write-Host "      Cache DNS vaciada." -ForegroundColor DarkGray

# ── 2. Firewall ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  [2/2] Configurando Firewall de Windows..." -ForegroundColor Yellow

$basePath = "C:\Program Files (x86)\Common Files\Adobe"
$exePath  = Get-ChildItem -Path $basePath -Filter "AdobeGCClient.exe" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName

if (-not $exePath) {
    Write-Host "      ERROR: AdobeGCClient.exe no encontrado en $basePath" -ForegroundColor Red
    Write-Host "      Asegurate de que Acrobat este instalado antes de correr el script." -ForegroundColor Red
} else {
    Write-Host "      Archivo encontrado: $exePath" -ForegroundColor DarkGray

    $reglas = @(
        @{ name = 'Adobe Genuine Service Block - IN';  dir = 'in'  }
        @{ name = 'Adobe Genuine Service Block - OUT'; dir = 'out' }
    )

    foreach ($regla in $reglas) {
        Remove-NetFirewallRule -DisplayName $regla.name -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $regla.name `
            -Direction $regla.dir `
            -Action Block `
            -Program $exePath `
            -Profile Any `
            -Enabled True | Out-Null
    }

    Write-Host "      Reglas de Entrada y Salida creadas." -ForegroundColor Green
}

Write-Host ""
Write-Host "  Proceso terminado." -ForegroundColor Cyan
Write-Host ""
