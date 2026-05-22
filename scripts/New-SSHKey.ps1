<#
.SYNOPSIS
    Genera una nueva clave SSH y la configura para usar con GitHub, GitLab, etc.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   Generador de Claves SSH            ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

Write-Header

# ── 1. Verificar ssh-keygen ───────────────────────────────────────────────────
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: ssh-keygen no encontrado." -ForegroundColor Red
    Write-Host "  Instala OpenSSH: Configuracion > Aplicaciones > Caracteristicas opcionales > OpenSSH" -ForegroundColor Yellow
    Pause; exit 1
}

# ── 2. Email / comentario ─────────────────────────────────────────────────────
$email = Read-Host "  Email para la clave (ej: usuario@gmail.com)"
if (-not $email.Trim()) { Write-Warning "Email requerido."; Pause; exit 1 }

# ── 3. Tipo de clave ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Tipo de clave:" -ForegroundColor Cyan
Write-Host "    [1] Ed25519  (recomendado - moderno y seguro)" -ForegroundColor Green
Write-Host "    [2] RSA 4096 (compatibilidad maxima)"
Write-Host ""
$tipoSel = Read-Host "  Opcion (Enter = 1)"
$tipo    = if ($tipoSel -eq '2') { 'rsa' } else { 'ed25519' }

# ── 4. Nombre del archivo ─────────────────────────────────────────────────────
Write-Host ""
$defaultName = "id_$tipo"
$keyName = Read-Host "  Nombre del archivo (Enter = $defaultName)"
if (-not $keyName.Trim()) { $keyName = $defaultName }

$sshDir  = "$env:USERPROFILE\.ssh"
$keyPath = "$sshDir\$keyName"

if (Test-Path $keyPath) {
    Write-Host ""
    Write-Host "  Ya existe una clave en: $keyPath" -ForegroundColor Yellow
    $overwrite = Read-Host "  Sobrescribir? (s/N)"
    if ($overwrite.Trim().ToLower() -ne 's') {
        Write-Host "  Cancelado." -ForegroundColor DarkGray
        Pause; exit 0
    }
}

# ── 5. Generar clave ──────────────────────────────────────────────────────────
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null

Write-Host ""
Write-Host "  Generando clave $tipo..." -ForegroundColor Yellow

if ($tipo -eq 'ed25519') {
    ssh-keygen -t ed25519 -C $email -f $keyPath
} else {
    ssh-keygen -t rsa -b 4096 -C $email -f $keyPath
}

if (-not (Test-Path "$keyPath.pub")) {
    Write-Host "  ERROR al generar la clave." -ForegroundColor Red
    Pause; exit 1
}

Write-Host ""
Write-Host "  Clave generada:" -ForegroundColor Green
Write-Host "    Privada : $keyPath"
Write-Host "    Publica : $keyPath.pub"

# ── 6. Configurar ssh-agent ───────────────────────────────────────────────────
Write-Host ""
Write-Host "  Configurando ssh-agent..." -ForegroundColor Cyan

$svc = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.StartType -eq 'Disabled') {
        Write-Host "  El servicio ssh-agent esta deshabilitado." -ForegroundColor Yellow
        Write-Host "  Ejecuta esto como Administrador para habilitarlo:" -ForegroundColor Yellow
        Write-Host "    Set-Service -Name ssh-agent -StartupType Manual; Start-Service ssh-agent" -ForegroundColor DarkCyan
    } else {
        if ($svc.Status -ne 'Running') {
            try { Start-Service ssh-agent } catch { Write-Host "  No se pudo iniciar ssh-agent (intenta como Admin)." -ForegroundColor Yellow }
        }
        if ((Get-Service ssh-agent).Status -eq 'Running') {
            ssh-add $keyPath
            Write-Host "  Clave agregada al agente SSH." -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ssh-agent no disponible." -ForegroundColor Yellow
}

# ── 7. Entrada en ~/.ssh/config (si nombre no es el default) ─────────────────
if ($keyName -ne $defaultName) {
    $configPath = "$sshDir\config"
    $configEntry = @"

# $keyName
Host github.com
    HostName github.com
    User git
    IdentityFile $keyPath
"@
    Add-Content -Path $configPath -Value $configEntry -Encoding UTF8
    Write-Host ""
    Write-Host "  Entrada agregada en ~/.ssh/config para GitHub." -ForegroundColor Green
}

# ── 8. Copiar clave publica al portapapeles ───────────────────────────────────
$pubKey = Get-Content "$keyPath.pub" -Raw
$pubKey.Trim() | Set-Clipboard

Write-Host ""
Write-Host "  Clave publica copiada al portapapeles!" -ForegroundColor Green
Write-Host ""
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  $($pubKey.Trim())" -ForegroundColor DarkCyan
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray

# ── 9. Instrucciones ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Proximos pasos:" -ForegroundColor Cyan
Write-Host "  GitHub : https://github.com/settings/ssh/new"
Write-Host "  GitLab : https://gitlab.com/-/profile/keys"
Write-Host ""
Write-Host "  Prueba tu conexion con:"
Write-Host "    ssh -T git@github.com" -ForegroundColor Yellow
Write-Host ""

Pause
