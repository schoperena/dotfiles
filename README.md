# dotfiles — schoperena

Configuración personal de PowerShell: prompt, módulos, temas y scripts.

## Setup en un equipo nuevo

```powershell
git clone https://github.com/schoperena/dotfiles "$env:USERPROFILE\.dotfiles"; & "$env:USERPROFILE\.dotfiles\setup.ps1"
```

> Requiere PowerShell 7+ y `winget` instalado (viene con Windows 11).

## ¿Qué instala?

| Componente | Origen |
|---|---|
| **oh-my-posh** | winget (`JanDeDobbeleer.OhMyPosh`) |
| **ImageMagick** | winget (`ImageMagick.Q16-HDRI`) |
| **Terminal-Icons** | PSGallery |
| **ps2exe** | PSGallery |
| **ImgConv** | este repo (`Modules/ImgConv/`) |
| **Temas OMP** | este repo (`night-owl`, `quick-term`, `.mytheme`) |
| **Scripts** | este repo (`CustomScripts/`) |
| **Perfil** | este repo (`Documents/PowerShell/Microsoft.PowerShell_profile.ps1`) |

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
