[CmdletBinding()]
param (
    # Ruta del archivo a verificar (ISO u otro)
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    # Hash esperado (opcional si se usa HashFile)
    [string]$ExpectedHash,

    # Archivo .sha256 / .sha1 / .md5 (opcional)
    [string]$HashFile,

    # Algoritmo
    [ValidateSet("SHA256","SHA1","SHA512","MD5")]
    [string]$Algorithm = "SHA256"
)

function Fail($msg, $code = 1) {
    Write-Host "❌ $msg" -ForegroundColor Red
    exit $code
}

if (-not (Test-Path $FilePath)) {
    Fail "El archivo no existe: $FilePath"
}

# Si se pasa un archivo de hash, leerlo
if ($HashFile) {
    if (-not (Test-Path $HashFile)) {
        Fail "El archivo de hash no existe: $HashFile"
    }

    $line = Get-Content $HashFile | Where-Object { $_ -match '\S' } | Select-Object -First 1

    if ($line -match '^([a-fA-F0-9]+)\s+\*?(.*)$') {
        $ExpectedHash = $matches[1]
        if (-not $FilePath) {
            $FilePath = $matches[2]
        }
    } else {
        Fail "Formato inválido en el archivo de hash"
    }
}

if (-not $ExpectedHash) {
    Fail "Debes proporcionar -ExpectedHash o -HashFile"
}

Write-Host "📦 Archivo   : $FilePath"
Write-Host "🔐 Algoritmo : $Algorithm"
Write-Host "🔍 Calculando checksum..."

$calculated = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash.ToLower()
$expected   = $ExpectedHash.ToLower()

Write-Host "Esperado  : $expected"
Write-Host "Calculado : $calculated"

if ($calculated -eq $expected) {
    Write-Host "✅ CHECKSUM OK — Archivo válido" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ CHECKSUM ERROR — NO coincide" -ForegroundColor Red
    exit 2
}
