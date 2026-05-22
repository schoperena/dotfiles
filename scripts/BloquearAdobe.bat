@echo off
title Bloqueador de Adobe - Ejecutar como Administrador
color 0A

:: 1. Verificar permisos de Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo =====================================================
    echo [!] ERROR: PRIVILEGIOS INSUFICIENTES
    echo =====================================================
    echo Por favor, cierra esta ventana, haz clic derecho sobre 
    echo el archivo .bat y selecciona "Ejecutar como administrador".
    echo.
    pause
    exit /b
)

echo Iniciando configuracion...
echo.

:: 2. Modificar el archivo HOSTS
set "hostsPath=%WINDIR%\System32\drivers\etc\hosts"
echo [1/2] Actualizando el archivo hosts...

:: Crear backup del archivo hosts
copy "%hostsPath%" "%hostsPath%.bak" /y >nul

:: Definir la lista de dominios a bloquear
set "domains=genuine.adobe.com prod.adobegenuine.com cc-api-data.adobe.io lcs-cops.adobe.io adobe.io ic.adobe.io practivate.adobe.com activate.adobe.com ereg.adobe.com activate.wip3.adobe.com wip3.adobe.com 3dns-3.adobe.com 3dns-2.adobe.com adobe-dns.adobe.com adobe-dns-2.adobe.com adobe-dns-3.adobe.com ereg.wip3.adobe.com activate-sea.adobe.com wwis-dubc1-vip60.adobe.com activate-sjc0.adobe.com hl2rcv.adobe.com lm.licenses.adobe.com lmlicenses.wip4.adobe.com"

:: Agregar dominios si no existen
for %%d in (%domains%) do (
    findstr /c:"0.0.0.0 %%d" "%hostsPath%" >nul
    if errorlevel 1 (
        echo 0.0.0.0 %%d >> "%hostsPath%"
        echo  - Bloqueado: %%d
    )
)

echo  - Vaciando cache DNS...
ipconfig /flushdns >nul

echo.
:: 3. Buscar y bloquear AdobeGCClient.exe en Firewall
echo [2/2] Configurando Firewall de Windows...
set "basePath=C:\Program Files (x86)\Common Files\Adobe"
set "exeName=AdobeGCClient.exe"
set "exePath="

:: Buscar el archivo recursivamente dentro de la carpeta Adobe
for /f "delims=" %%i in ('dir "%basePath%\%exeName%" /s /b 2^>nul') do (
    set "exePath=%%i"
    goto :found
)

:found
if "%exePath%"=="" (
    color 0C
    echo [!] ERROR: No se encontro %exeName% en %basePath%
    echo Asegurate de que Acrobat este instalado antes de correr el script.
    goto :end
)

echo  - Archivo encontrado: "%exePath%"

:: Eliminar reglas previas para evitar duplicados (ignora errores si no existen)
netsh advfirewall firewall delete rule name="Adobe Genuine Service Block - IN" >nul 2>&1
netsh advfirewall firewall delete rule name="Adobe Genuine Service Block - OUT" >nul 2>&1

:: Crear nuevas reglas de Entrada y Salida
netsh advfirewall firewall add rule name="Adobe Genuine Service Block - IN" dir=in action=block program="%exePath%" profile=any >nul
netsh advfirewall firewall add rule name="Adobe Genuine Service Block - OUT" dir=out action=block program="%exePath%" profile=any >nul

echo  - Reglas de Entrada y Salida creadas exitosamente.

:end
echo.
echo =====================================================
echo --- PROCESO TERMINADO ---
echo =====================================================
pause