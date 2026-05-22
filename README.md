# dotfiles — schoperena

Configuración personal de PowerShell: prompt, módulos, temas y scripts.

## Setup en un equipo nuevo

```powershell
git clone https://github.com/schoperena/dotfiles "$env:USERPROFILE\.dotfiles"; & "$env:USERPROFILE\.dotfiles\setup.ps1"
```

> Requiere PowerShell 7+ y `winget` instalado (viene con Windows 11).

## ¿Qué instala?

El script pide selección interactiva para navegadores y herramientas AI. El resto se instala siempre.

| Componente | Origen | Selección |
|---|---|---|
| **Git** | winget | siempre |
| **GitHub CLI** | winget | siempre |
| **oh-my-posh** | winget | siempre |
| **ImageMagick** | winget | siempre |
| **VLC** | winget | siempre |
| **Visual Studio Code** | winget | siempre |
| **NanaZip** | winget | siempre |
| **WhatsApp** | Microsoft Store | siempre |
| **Chrome / Brave / Firefox / LibreWolf** | winget | multi-selección |
| **Claude Desktop** | winget | multi-selección |
| **Claude Code** | npm | multi-selección |
| **Codex CLI** | npm | multi-selección |
| **Terminal-Icons** | PSGallery | siempre |
| **ps2exe** | PSGallery | siempre |
| **ImgConv** | este repo | siempre |
| **Temas OMP** | este repo | siempre |
| **Perfil + Scripts** | este repo | siempre |

## Estructura

```
dotfiles/
├── Documents/
│   └── PowerShell/
│       ├── Microsoft.PowerShell_profile.ps1
│       ├── night-owl.omp.json        ← tema activo
│       ├── quick-term.omp.json
│       ├── .mytheme.omp.json
│       ├── powershell.config.json
│       └── CustomScripts/
│           ├── MenuScripts.ps1       ← lanzar con: toolbox
│           ├── FormatearDisco.ps1
│           ├── deblotear_TCL10L.ps1
│           ├── renombrar_timelapse.ps1
│           ├── stirling-sch.ps1
│           ├── tree.ps1
│           ├── verify-checksum.ps1
│           ├── win11_rpd_patch.ps1
│           ├── BloquearAdobe.bat
│           ├── calc_digito_de_verificacion.py
│           └── procesar_notebook.py
└── Modules/
    └── ImgConv/                      ← conversor de imágenes con ImageMagick
```

## Comandos rápidos

| Comando | Descripción |
|---|---|
| `toolbox` | Abre el hub de scripts personales |
| `ImgConv` | Convierte imágenes (HEIC, PNG, JPG, etc.) |

## Scripts en `toolbox`

| Script | Descripción |
|---|---|
| `MenuScripts.ps1` | Este mismo hub |
| `New-SSHKey.ps1` | Genera clave SSH (Ed25519 o RSA 4096) para GitHub/GitLab |
| `FormatearDisco.ps1` | Formatea discos externos (NTFS / exFAT / FAT32) — requiere Admin |
| `deblotear_TCL10L.ps1` | Elimina bloatware del TCL 10L vía ADB |
| `renombrar_timelapse.ps1` | Renombra imágenes de timelapse en secuencia numérica |
| `stirling-sch.ps1` | Instala Stirling-PDF apuntando al servidor interno |
| `tree.ps1` | Muestra árbol de directorios |
| `verify-checksum.ps1` | Verifica checksum SHA256/SHA1/MD5 de un archivo |
| `win11_rpd_patch.ps1` | Parche para habilitar RDP en Windows 11 Home |
