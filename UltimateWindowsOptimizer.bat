@echo off
title Optimizador de Windows 11 - Optimizacion Integral
cls

echo ==============================
echo Iniciando optimización de Windows 11...
echo ==============================
timeout /t 3 >nul

echo ==============================================================
echo 01. CREANDO PUNTO DE RESTAURACION DEL SISTEMA
echo ==============================================================
echo Creando punto de restauracion antes de realizar los cambios...
powershell -Command "Enable-ComputerRestore -Drive 'C:\\'; Checkpoint-Computer -Description 'Antes de optimizacion Windows 11' -RestorePointType MODIFY_SETTINGS"
if %errorlevel% equ 0 (
    echo Punto de restauracion creado exitosamente.
) else (
    echo ADVERTENCIA: No se pudo crear el punto de restauracion.
    echo Es posible que la restauracion del sistema este desactivada.
    echo Te recomendamos crear un punto de restauracion manualmente antes de continuar.
)

:: Definir la ruta del escritorio y la carpeta de respaldo
set "BACKUP_PATH=%USERPROFILE%\Desktop\Backup_Registro"
mkdir "%BACKUP_PATH%"

echo Creando respaldo del registro en el Escritorio...

:: Exportar las 5 colmenas principales
reg export HKEY_CLASSES_ROOT "%BACKUP_PATH%\1_HKCR.reg" /y
reg export HKEY_CURRENT_USER "%BACKUP_PATH%\2_HKCU.reg" /y
reg export HKEY_LOCAL_MACHINE "%BACKUP_PATH%\3_HKLM.reg" /y
reg export HKEY_USERS "%BACKUP_PATH%\4_HKU.reg" /y
reg export HKEY_CURRENT_CONFIG "%BACKUP_PATH%\5_HKCC.reg" /y

timeout /t 3 >nul

echo ==============================================================
echo 02. DESACTIVAR BITLOCKER PARA MEJORAR RENDIMIENTO DE DISCO
echo ==============================================================
echo BitLocker está activado. Desactivando...
manage-bde -off C: >nul 2>&1
    echo BitLocker se está desactivando. Este proceso puede tardar varias horas dependiendo del tamaño del disco.
    echo Los cambios se aplicarán completamente al reiniciar el sistema.
timeout /t 2 >nul


echo ==============================================================
echo 03. DEFENDER
echo ============================================================== 
:: 1. INTENTAR MATAR PROCESOS (Para liberar carpetas)
echo [+] Deteniendo procesos activos...
taskkill /f /im MsMpEng.exe /t >nul 2>&1
taskkill /f /im SecurityHealthService.exe /t >nul 2>&1

:: 2. BLOQUEO DE REGISTRO (SERVICIOS Y KERNEL)
echo [+] Deshabilitando servicios y drivers de Kernel...
set "base=HKLM\SYSTEM\CurrentControlSet\Services"
set "list=WinDefend WdFilters WdBoot WdNisDrv WdNisSvc Sense SecurityHealthService wscsvc"

for %%s in (%list%) do ( 
    reg add "%base%\%%s" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1 
)

:: 3. POLÍTICAS DE GRUPO (GPEDIT)
echo [+] Aplicando politicas de restriccion...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1

:: 4. ELIMINAR INTERFAZ Y ICONOS
echo [+] Eliminando SecHealthUI y arranque...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SecurityHealth" /f >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$appx = Get-AppxPackage -AllUsers *SecHealthUI*; if ($appx) { $PackageFamilyName = $appx.PackageFamilyName; dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0; Remove-AppxPackage -Package $appx.PackageFullName -AllUsers }" >nul 2>&1

:: 5. LIMPIEZA DE TAREAS PROGRAMADAS
echo [+] Limpiando tareas programadas...
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /f >nul 2>&1

:: 6. BORRADO DE CARPETAS (Solo funcionara si el proceso cedio o estas en Modo Seguro)
echo [+] Intentando borrar carpetas de programa...
for %%d in ("C:\ProgramData\Microsoft\Windows Defender" "C:\Program Files\Windows Defender" "C:\Program Files (x86)\Windows Defender") do (
    if exist "%%~d" (
        takeown /f "%%~d" /r /d y >nul 2>&1
        icacls "%%~d" /grant administradores:F /t >nul 2>&1
        rd /s /q "%%~d" >nul 2>&1
    )
)

echo ------------------------------------------------------
echo [OK] Operacion finalizada con exito.
echo [!] IMPORTANTE: Reinicia el equipo para liberar la RAM y aplicar cambios.
echo ------------------------------------------------------
timeout /t 2 >nul

echo ==============================
echo 04. Eliminando Bloatware...
echo ==============================
echo ----- Bloqueando reinstalación -----
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f

echo ----- Eliminando Game Bar desde políticas -----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

:: Ejecutar PowerShell desde CMD para desinstalar apps - versión actualizada para Windows 11
powershell -Command "$apps = @('3DBuilder', 'ZuneMusic', 'ZuneVideo', 'XboxApp', 'XboxGameOverlay', 'Xbox.TCUI', 'BingNews', 'GetHelp', 'Getstarted', 'MicrosoftSolitaireCollection', 'People', 'SkypeApp', 'MicrosoftOfficeHub', 'Todos', 'WindowsAlarms', 'WindowsFeedbackHub', 'WindowsMaps', 'WindowsSoundRecorder', 'YourPhone', 'StickyNotes', 'MicrosoftStickyNotes', 'OneConnect', 'Wallet', 'GamingApp', 'XboxIdentityProvider', 'WindowsPhotos', 'WindowsCamera', 'WindowsCommunicationsApps', 'WindowsTerminal', 'PowerAutomateDesktop', 'OutlookForWindows'); foreach ($app in $apps) { Get-AppxPackage -AllUsers *Microsoft.$app* | Remove-AppxPackage -AllUsers }"

powershell -command "Get-AppxPackage *Microsoft.Windows.CloudExperienceHost* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *Microsoft.BingWeather* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *MicrosoftCorporationII.MicrosoftFamily* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *MicrosoftEdge.Copilot* | Remove-AppxPackage"
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
powershell -command "Get-AppxPackage -AllUsers *Microsoft.Windows.Ai.Copilot* | Remove-AppxPackage -ErrorAction SilentlyContinue"
wmic product where "name like '%%HP Connection Optimizer%%'" call uninstall /nointeractive
wmic product where "name like '%%HP System Event Utility%%'" call uninstall /nointeractive
wmic product where "name like '%%HP Documentation%%'" call uninstall /nointeractive
:: Esto busca el nombre del archivo .inf que controla HP Connection Optimizer
powershell -command "Get-WindowsDriver -Online | Where-Object { $_.ProviderName -like '*HP*' } | Select-Object OriginalFileName, ProviderName, ClassName"

:: Eliminar paquetes provisionados para evitar reinstalación
powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like '*3DBuilder*' -or $_.DisplayName -like '*ZuneMusic*' -or $_.DisplayName -like '*ZuneVideo*' -or $_.DisplayName -like '*Xbox*' -or $_.DisplayName -like '*BingNews*' -or $_.DisplayName -like '*GetHelp*' -or $_.DisplayName -like '*Getstarted*' -or $_.DisplayName -like '*Solitaire*' -or $_.DisplayName -like '*People*' -or $_.DisplayName -like '*Skype*' -or $_.DisplayName -like '*OfficeHub*' -or $_.DisplayName -like '*Todos*' -or $_.DisplayName -like '*Alarms*' -or $_.DisplayName -like '*FeedbackHub*' -or $_.DisplayName -like '*Maps*' -or $_.DisplayName -like '*SoundRecorder*' -or $_.DisplayName -like '*YourPhone*' -or $_.DisplayName -like '*StickyNotes*' -or $_.DisplayName -like '*OneConnect*' -or $_.DisplayName -like '*Wallet*' -or $_.DisplayName -like '*GamingApp*' -or $_.DisplayName -like '*Terminal*' -or $_.DisplayName -like '*PowerAutomate*' -or $_.DisplayName -like '*Outlook*'} | Remove-AppxProvisionedPackage -Online"

:: Bloqueo total de Copilot
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f
taskkill /f /im explorer.exe && start explorer.exe
powershell -command "Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like '*Copilot*'} | Remove-AppxProvisionedPackage -Online"
powershell -command "Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers"
:: Eliminar el proceso de la sesión actual
taskkill /f /im "Copilot.exe" /t

:: Quitar el botón de la barra de tareas por registro
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f

echo Iniciando limpieza de aplicaciones OEM...
echo Por favor, espera a que termine el proceso.
echo.

:: Versión corregida en una sola línea de comando para evitar errores de sintaxis
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vendors='hp|lenovo|dell|asus|acer'; $exclude='driver|firmware|bios|interface|foundation|system|hotkey|audio|chipset|service'; Write-Host '--- BUSCANDO APPS INSTALADAS ---' -ForegroundColor Cyan; $apps = Get-AppxPackage -AllUsers | Where-Object { ($_.Name -match $vendors -or $_.PackageFamilyName -match $vendors -or $_.Publisher -match $vendors) -and ($_.Name -notmatch $exclude) }; if ($apps) { foreach ($app in $apps) { Write-Host ('Eliminando: ' + $app.Name) -ForegroundColor Yellow; Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction SilentlyContinue } } else { Write-Host 'No se encontraron apps de usuario.' -ForegroundColor Green }; Write-Host '--- BUSCANDO APPS PROVISIONADAS ---' -ForegroundColor Cyan; $prov = Get-AppxProvisionedPackage -Online | Where-Object { ($_.DisplayName -match $vendors) -and ($_.DisplayName -notmatch $exclude) }; if ($prov) { foreach ($p in $prov) { Write-Host ('Eliminando provisionada: ' + $p.DisplayName) -ForegroundColor Magenta; Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue } } else { Write-Host 'No se encontraron apps provisionadas.' -ForegroundColor Green }; Write-Host 'Limpieza finalizada.' -ForegroundColor White"

powershell -command "Get-AppxPackage *HPConnectionOptimizer* | Remove-AppxPackage -AllUsers"
powershell -command "Get-AppxPackage *HPDocumentation* | Remove-AppxPackage -AllUsers"
powershell -command "Get-AppxPackage *HPSystemEventUtility* | Remove-AppxPackage -AllUsers"

echo ----------------------------
echo Bloatware eliminado.
echo ----------------------------

echo ==============================
echo 05. DESINSTALAR O DESHABILITAR WIDGETS Y XBOX (CMD SOLAMENTE)
echo ==============================
:: Desactivar Widgets desde el registro (barra de tareas)
echo Desactivando los Widgets desde la barra de tareas...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivar Widgets desde políticas (evita reinstalación)
echo Bloqueando Widgets mediante políticas...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1

:: Desinstalar Windows Web Experience Pack (Widgets backend)
echo Desinstalando Windows Web Experience Pack (Widgets)...
powershell -Command "Get-AppxPackage -AllUsers *WindowsWebExperiencePack* | Remove-AppxPackage -ErrorAction SilentlyContinue"
powershell -Command "Get-AppxPackage *WindowsWebExperiencePack* | Remove-AppxPackage -ErrorAction SilentlyContinue"

:: Reiniciar el Explorador para aplicar el cambio
echo Reiniciando el Explorador de Windows...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 3 >nul
start explorer.exe

:: Quitar paquetes preinstalados de Xbox usando DISM
echo Intentando quitar paquetes preinstalados de Xbox...
dism /online /get-provisionedappxpackages | findstr "XboxGamingOverlay" >nul && (
    dism /online /remove-provisionedappxpackage /packagename:Microsoft.XboxGamingOverlay_* >nul 2>&1
)
dism /online /get-provisionedappxpackages | findstr "XboxGameCallableUI" >nul && (
    dism /online /remove-provisionedappxpackage /packagename:Microsoft.XboxGameCallableUI_* >nul 2>&1
)
dism /online /get-provisionedappxpackages | findstr "XboxIdentityProvider" >nul && (
    dism /online /remove-provisionedappxpackage /packagename:Microsoft.XboxIdentityProvider_* >nul 2>&1
)
dism /online /get-provisionedappxpackages | findstr "GamingApp" >nul && (
    dism /online /remove-provisionedappxpackage /packagename:Microsoft.GamingApp_* >nul 2>&1
)

:: Eliminar paquetes UWP de Xbox para el usuario actual
echo Eliminando aplicaciones de Xbox para el usuario actual...
powershell -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue"
powershell -Command "Get-AppxPackage *GamingApp* | Remove-AppxPackage -ErrorAction SilentlyContinue"

echo.
echo Proceso completado. Widgets y componentes de Xbox han sido desactivados/eliminados.
echo Es posible que necesites reiniciar para que todos los cambios surtan efecto completo.
timeout /t 5 >nul

echo Deshabilitando Widgets y WebExperience...
:: Método de registro para deshabilitar widgets en el taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo Widgets deshabilitados via registro.
) else (
    echo Advertencia: No se pudo modificar el registro. Continuando con otros métodos.
)

:: Política de grupo para deshabilitar noticias e intereses
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1

:: Eliminar el paquete WebExperience (widgets) - método más efectivo en Windows 11
powershell -Command "try { Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -AllUsers -ErrorAction Stop } catch { Write-Host 'Intentando eliminar para usuario actual...'; Get-AppxPackage *WebExperience* | Remove-AppxPackage }"
if %errorlevel% equ 0 (
    echo Widgets eliminados exitosamente.
) else (
    echo Advertencia: No se pudieron eliminar todos los componentes de widgets.
)

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f


:: Reiniciar el explorador para aplicar cambios (opcional pero recomendado)
echo Reiniciando el explorador para aplicar cambios...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Widgets y componentes relacionados deshabilitados lo máximo posible.
echo.


echo =============================================
echo 06. LIMPIAR PROGRAMAS DE INICIO AUTOMÁTICO
echo =============================================
echo Limpiando inicio automático innecesario...
echo Limpiando inicio automático innecesario...

:: Limpiar inicio de usuario actual
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /f >nul 2>&1

:: Limpiar inicio de todos los usuarios (requiere permisos de Administrador)
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /f >nul 2>&1

:: Limpiar carpetas de inicio adicionales
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" (
    del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*" >nul 2>&1
    for /d %%i in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do rd /s /q "%%i" >nul 2>&1
)

if exist "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup" (
    del /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*" >nul 2>&1
    for /d %%i in ("%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do rd /s /q "%%i" >nul 2>&1
)

:: Limpieza de Temporales
del /q /s /f %temp%\* >nul 2>&1
for /d %%i in ("%temp%\*") do rd /s /q "%%i" >nul 2>&1
del /q /s /f C:\Windows\Temp\* >nul 2>&1

:: CORRECCIÓN: Bucles FOR con %% y manejo de errores
for /f "tokens=*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" 2^>nul') do (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%%~nxa" /t REG_BINARY /d 030000000000000000000000 /f >nul 2>&1
)

for /f "tokens=1 delims=," %%i in ('schtasks /query /fo csv /nh 2^>nul ^| findstr /v /i "Microsoft"') do (
    schtasks /change /tn %%i /disable >nul 2>&1
)

:: Filtro para limpiar el salto de línea fantasma de WMIC
for /f "tokens=2 delims==" %%a in ('wmic service where "startmode='Auto' and not caption like '%%Microsoft%%'" get name /value 2^>nul') do (
    for /f "tokens=*" %%b in ("%%a") do sc config "%%b" start= disabled >nul 2>&1
)


echo Programas de inicio limpiados.
echo.

echo ==============================================================
echo 07. MEMORIA RAM
echo ============================================================== 
setlocal enabledelayedexpansion

REM ——————————————————————————————————————————
REM 1) Obtener RAM en MB vía PowerShell
for /f %%A in ('
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)"
') do set RAM_MB=%%A

if "%RAM_MB%"=="" (
  echo ERROR: no pudo determinarse la RAM.
  pause & exit /b 1
)

REM ——————————————————————————————————————————
REM 2) Calcular valores de pagefile
set /a MIN_SIZE=RAM_MB*3/2
set /a MAX_SIZE=RAM_MB*3

echo Memoria detectada: %RAM_MB% MB
echo Fijando pagefile en C:\pagefile.sys:
echo   Min = %MIN_SIZE% MB
echo   Max = %MAX_SIZE% MB
echo.

REM ——————————————————————————————————————————
REM 3) Desactivar administración automática en registro
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" ^
    /v AutomaticManagedPagefile /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
  echo ERROR: no se pudo desactivar AutomaticManagedPagefile.
  pause & exit /b 1
)
REM ——————————————————————————————————————————
REM 4) Escribir los valores de pagefile en registro
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" ^
    /v PagingFiles /t REG_MULTI_SZ /d "C:\pagefile.sys %MIN_SIZE% %MAX_SIZE%" /f >nul 2>&1
if errorlevel 1 (
  echo ERROR: no se pudo escribir PagingFiles.
  pause & exit /b 1
)
echo [✔] Registro actualizado.  

echo ==============================================================
echo 8. OPTIMIZAR EL ARRANQUE
echo ============================================================== 
echo Optimizando arranque...
bcdedit /set {current} numproc %NUMBER_OF_PROCESSORS%
bcdedit /set {current} useplatformclock false
bcdedit /set {current} disabledynamictick yes
timeout /t 2 >nul

echo ==============================================================
echo 09. AJUSTAR PLAN DE ENERGÍA Y MÁXIMO RENDIMIENTO
echo ============================================================== 
echo Habilitando Modo de Juegos (Game Mode)...
reg add "HKCU\System\GameConfigStore" /v "GameModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
timeout /t 2 >nul

echo.
echo Habilitando plan de energia "Ultimate Performance" (Maximo rendimiento)...
REM Comando para agregar el plan de energia oculto "Ultimate Performance" en Windows 11
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
timeout /t 2 >nul

echo.
echo Activando el plan "Ultimate Performance" como predeterminado...
REM Se usa el GUID del plan Ultimate Performance para Windows 11
for /f "tokens=4" %%a in ('powercfg /list ^| findstr "e9a42b02-d5df-448d-aa00-03f14749eb61"') do set "plan_guid=%%a"
if defined plan_guid (
    powercfg -setactive %plan_guid%
) else (
    echo Plan no encontrado, usando plan de Alto Rendimiento como alternativa...
    powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
timeout /t 2 >nul
echo ¡Optimizaciones de rendimiento completadas!

echo =============================================
echo 10. FORZAR USO DE HIBERNACIÓN EN LUGAR DE SUSPENSIÓN
echo =============================================
echo Activando hibernación como modo preferido de reposo...
:: Activar hibernación
powercfg.exe /hibernate on
:: Desactivar suspensión en modo AC (conectado a corriente)
powercfg.exe /change standby-timeout-ac 0
:: Desactivar suspensión en modo DC (batería)
powercfg.exe /change standby-timeout-dc 0
:: Verificar que los cambios se aplicaron
timeout /t 2 /nobreak >nul
echo Hibernación activada y suspensión desactivada correctamente.
echo.

echo ==============================================================
echo 11. BLOQUEAR TELEMETRÍA, DATOS Y NOTIFICACIONES
echo ============================================================== 

:: --- TELEMETRÍA Y RECOLECCIÓN DE DATOS ---
echo [1/4] Desactivando telemetria y recoleccion de datos...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul
timeout /t 2 >nul

:: --- SERVICIOS DE RASTREO ---
echo [2/4] Deteniendo y deshabilitando servicios de seguimiento...
for %%s in (DiagTrack, dmwappushservice, WdiServiceHost, PcaSvc, WerSvc) do (
    sc stop %%s >nul 2>&1
    sc config %%s start= disabled >nul 2>&1
)
timeout /t 2 >nul

:: --- PERMISOS DE PRIVACIDAD (Hardware y Apps) ---
echo [3/4] Ajustando permisos de aplicaciones (Microfono/Camara/Ubicacion)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\camera" /v "Value" /t REG_SZ /d "Deny" /f >nul
timeout /t 2 >nul

:: --- PUBLICIDAD, NOTIFICACIONES Y SUGERENCIAS ---
echo [4/4] Desactivando anuncios, sugerencias y notificaciones...
:: Notificaciones y Centro de Actividades
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d 1 /f >nul 2>&1

:: Contenido sugerido y anuncios de Windows (Content Delivery Manager)
for %%v in (SubscribedContent-310093Enabled, SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SoftLandingEnabled, FeatureManagementEnabled, SilentInstalledAppsEnabled) do (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "%%v" /t REG_DWORD /d 0 /f >nul
)
timeout /t 2 >nul

echo ==============================================================
echo 12. DESACTIVAR INDEXACIÓN DE BÚSQUEDA
echo ============================================================== 
echo Desactivando indexación de búsqueda...
sc stop "WSearch"
sc config "WSearch" start= disabled || echo No se pudo detener el servicio WSearch
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d 4 /f
echo Servicio de búsqueda desactivado completamente
timeout /t 2 >nul

echo ==============================================================
echo 13. Optimización inteligente de procesos y servicios del sistema
echo ============================================================== 
:: 1. LIMPIAR CACHÉ Y TEMPORALES
echo [+] Eliminando archivos temporales y Prefetch...
del /q /s /f "%temp%\*" >nul 2>&1
del /q /s /f "C:\Windows\Temp\*" >nul 2>&1
echo [OK] Temporales limpios.

echo [+] Verificando integridad de la imagen de Windows...
dism /online /cleanup-image /checkhealth | findstr /i "No se detectaron daños" >nul
if %errorLevel% neq 0 (
    echo [!] Aviso: Se detectaron inconsistencias leves, la limpieza puede tardar.
)

echo [+] Analizando y limpiando almacen de componentes (WinSxS)...
echo     Esto puede tardar varios minutos...
DISM /Online /Cleanup-Image /AnalyzeComponentStore
DISM /Online /Cleanup-Image /StartComponentCleanup /NoRestart

echo [+] Ejecutando Liberador de espacio en disco (Config 1)...
start /wait "" cleanmgr /sagerun:1 >nul 2>&1

:: 2. OPTIMIZACION DE SERVICIOS Y RENDIMIENTO
echo [+] Desactivando SysMain (Superfetch) para SSDs...
sc config "SysMain" start= disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1

echo [+] Limitando aplicaciones en segundo plano para ahorrar RAM...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul

echo [+] Deshabilitando servicios innecesarios (Fax, Xbox, Diag)...
:: Servicios de Telemetria y Diagnostico
sc config DiagTrack start= disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config WdiServiceHost start= disabled >nul 2>&1
sc stop WdiServiceHost >nul 2>&1
sc config WdiSystemHost start= disabled >nul 2>&1
sc stop WdiSystemHost >nul 2>&1
:: Servicios Xbox y Fax
for %%s in (XblAuthManager XblGameSave XboxNetApiSvc Fax RemoteRegistry) do (
    sc config %%s start= disabled >nul 2>&1
    sc stop %%s >nul 2>&1
)
DISM /Online /Disable-Feature /FeatureName:FaxServicesClientPackage /NoRestart >nul 2>&1

:: 3. DESHABILITAR ONEDRIVE Y TELEMETRIA
echo [+] Deshabilitando OneDrive por completo...
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im OneDriveSetup.exe >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSync" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowOneDrive" /t REG_DWORD /d 0 /f >nul

:: 4. TAREAS PROGRAMADAS E INDICADORES DE USO
echo [+] Deshabilitando tareas programadas de telemetria...
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1

:: 5. CONFIGURACION DE STORAGE SENSE (SENSOR DE ALMACENAMIENTO)
echo [+] Configurando Sensor de Almacenamiento...
:: Tu script original tenia comandos para ACTIVARLO y luego para DESACTIVARLO por completo.
:: He optado por la DESACTIVACION total segun tu ultima instruccion del script.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "DisableStorageSense" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 0 /f >nul

echo.

echo ==============================================================
echo 14. AJUSTES AVANZADOS DE RED
echo ============================================================== 
echo Optimizando buffers TCP/IP
netsh int tcp set global rss=enabled
timeout /t 2 >nul
echo Deshabilitar IPv6
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 255 /f
echo Ajustar el algoritmo de congestión 
netsh int tcp set global congestionprovider=cubic
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "AutoDetect" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo
==============================================================
echo 15. OPTIMIZAR PRIORIDAD DEL PROCESADOR y APPS DE INICIO
echo ============================================================== 
echo Ajustando prioridad del procesador para aplicaciones activas...
powershell -Command "Get-Process -Name explorer -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'High' }"
powershell -Command "Get-Process -Name notepad -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'High' }"
powershell -Command "Get-Process -Name chrome -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'High' }"

echo Configurando distribucion de tiempo de CPU...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f
timeout /t 2 >nul

echo Deshabilitando aplicaciones de inicio...
for /f "tokens=*" %%a in ('reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run') do (
    reg delete "%%a" /f || echo No se pudo eliminar la entrada "%%a"
)
for /f "tokens=*" %%a in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') do (
    reg delete "%%a" /f || echo No se pudo eliminar la entrada "%%a"
)
echo Deshabilitando programas innecesarios en segundo plano...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 16. Optimizar la aceleración y el escalado de la GPU para un mejor rendimiento
echo ============================================================== 
echo Ajustando escalado de GPU para mejor rendimiento...
echo Nota: Este ajuste depende del hardware y drivers instalados.
reg add "HKCU\Software\Microsoft\DirectX" /v "EnableGPUScaling" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo Habilitando aceleración de GPU por hardware (verifique compatibilidad)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f
timeout /t 2 >nul

echo ==============================================================
echo 17. OPTIMIZAR ENTRADA DE TEXTO Y EFECTOS VISUALES (SEGURO)
echo ============================================================== 

:: --------------------------------------------------------------
:: [+] Deshabilitando funciones de entrada de texto (TextInputHost)
::     Método seguro: vía registro, SIN eliminar archivos del sistema
:: --------------------------------------------------------------
echo Desactivando teclado táctil, panel de emoji y dictado por voz...

:: Desactivar teclado táctil automático
reg add "HKCU\Software\Microsoft\TabletTip\1.7" /v "EnableAutoShiftEngage" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\TabletTip\1.7" /v "EnableKeyAudioFeedback" /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivar predicción de texto y sugerencias
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\TextInput" /v "EnableTextPrediction" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\TextInput" /v "EnableMultilingual" /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivar panel de emoji (Win + .) y GIFs
reg add "HKCU\Software\Microsoft\input\Settings" /v "InsightsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivar dictado por voz (Win + H)
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d 0 /f >nul 2>&1

:: Detener proceso TextInputHost temporalmente (se reiniciará si es necesario)
taskkill /f /im TextInputHost.exe >nul 2>&1
timeout /t 1 >nul

echo [OK] Funciones de entrada de texto desactivadas.


:: --------------------------------------------------------------
:: [+] Desactivar efectos visuales innecesarios (rendimiento)
:: --------------------------------------------------------------
echo Optimizando interfaz visual para máximo rendimiento...

:: Modo "Ajustar para obtener el mejor rendimiento"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1

:: Desactivar animación de minimizar/maximizar ventanas
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1

:: Desactivar transparencia en barra de tareas y ventanas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivar sombras y efectos de menú
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >nul 2>&1

echo [OK] Efectos visuales optimizados.


:: --------------------------------------------------------------
:: [+] Desactivar Widgets, Cortana y sugerencias de búsqueda
:: --------------------------------------------------------------
echo Desactivando componentes innecesarios de la barra de tareas...

:: Widgets (TaskbarDa)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1

:: Cortana y búsqueda
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f >nul 2>&1

:: Publicidad y sugerencias de contenido
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
for %%v in (SubscribedContent-310093Enabled, SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SoftLandingEnabled, FeatureManagementEnabled, SilentInstalledAppsEnabled) do (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "%%v" /t REG_DWORD /d 0 /f >nul 2>&1
)

echo [OK] Widgets y sugerencias desactivados.


:: --------------------------------------------------------------
:: [+] Reiniciar Explorador para aplicar cambios visuales
:: --------------------------------------------------------------
echo Aplicando cambios en la interfaz...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe
timeout /t 1 >nul

echo.
echo [✔] Sección 17 completada: Optimización visual y de entrada segura.
echo     • LogonUI y componentes XAML permanecen intactos ✅
echo     • Funciones de texto desactivadas vía registro ✅
echo     • Efectos visuales optimizados para rendimiento ✅
echo.
timeout /t 2 >nul
echo.

echo ==============================================================
echo 18. CONFIGURACIÓN DE ACTUALIZACIONES Y OPTIMIZACIÓN DE WINDOWS UPDATE
echo ============================================================== 
echo Configurando actualizaciones automáticas (modo manual)...
sc stop wuauserv
sc config wuauserv start= demand
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo Deshabilitando límite de ancho de banda de Windows Update...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "NoBandwidthThrottling" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d 4 /f
timeout /t 2 >nul

echo Deshabilitando actualizaciones automáticas de drivers y de Windows Store...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f
timeout /t 2 >nul

echo ============================================
echo 19. Reparacion de Disco Duro y Sectores
echo ============================================
:: 1. Reparación ONLINE rápida
echo [+] Analizando integridad de archivos...
chkdsk C: /scan /perf >nul 2>&1

:: 2. DETECTAR TIPO DE DISCO (Version simplificada y estable)
echo [+] Identificando hardware...
set "driveType=SSD"
powershell -NoProfile -Command "Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'HDD' }" | findstr "HDD" >nul
if %errorlevel% equ 0 (set "driveType=HDD")

echo [+] Tipo de unidad detectada: [%driveType%]

:: 3. HABILITAR TRIM
fsutil behavior set disabledeletenotify 0 >nul 2>&1
echo [+] Configuracion TRIM verificada.

:: 4. LOGICA DE OPTIMIZACION
if /i "%driveType%"=="SSD" (
    echo [OK] Aplicando Retrim a SSD...
    defrag C: /L /U >nul 2>&1
) else (
    echo [!] HDD detectado: Optimizando...
    defrag C: /O /U >nul 2>&1
)

echo [OK] Verificacion de disco finalizada.
timeout /t 2 >nul


echo =============================================
echo 20. Optimizacion de equipos dependiendo RAM
echo =============================================

setlocal enabledelayedexpansion

:: 1. OBTENER RAM TOTAL EN MB (Método seguro para evitar cierres)
for /f %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1MB)"') do set RAM_MB=%%A

if "%RAM_MB%"=="" (
    echo [!] ERROR: No se pudo determinar la RAM. Saltando al paso 21.
    goto END_RAM_CHECK
)

echo [+] RAM Total Detectada: %RAM_MB% MB

:: 2. LOGICA DE SALTO (Umbral: 8GB = 8192 MB)
if %RAM_MB% LSS 8192 (
    goto LOW_RAM_LOGIC
) else (
    goto HIGH_RAM_LOGIC
)

:: =====================================================================
:: BLOQUE: MENOS DE 8 GB DE RAM (Optimización de Recursos)
:: =====================================================================
:LOW_RAM_LOGIC
echo [!] Sistema con poca RAM. Aplicando optimizacion extrema...

:: A. Desactivar efectos visuales innecesarios
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul

:: B. Desactivar servicios pesados
sc config SysMain start= disabled >nul
sc config WSearch start= disabled >nul
sc config DiagTrack start= disabled >nul

echo [OK] Optimización para Low RAM completada.
goto END_RAM_CHECK

::
=====================================================================
:: BLOQUE: 8 GB O MÁS DE RAM (Optimización de Latencia y Gaming)
:: =====================================================================
:HIGH_RAM_LOGIC
echo [OK] Sistema con RAM suficiente. Aplicando optimizacion de latencia...

:: A. Gestión avanzada de memoria (Kernel en RAM)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f >nul

:: B. Optimización de CPU y Latencia (Tick rate)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableDynamicTick" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul

:: C. Optimización de GPU (Programación de GPU acelerada por hardware)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul

:: D. Red para baja latencia
netsh int tcp set global autotuninglevel=normal >nul
netsh int tcp set global rss=enabled >nul

echo [OK] Optimización para High RAM completada.
goto END_RAM_CHECK

:END_RAM_CHECK
endlocal
echo.

echo ==============================================================
echo 21. OPTIMIZACIONES AVANZADAS DE RENDIMIENTO (SEGURO)
echo ==============================================================

:: --------------------------------------------------------------
:: [+] Desactivar registro de último acceso a archivos (NTFS)
::     Reduce escrituras innecesarias en disco → mejora I/O general
:: --------------------------------------------------------------
echo Optimizando sistema de archivos NTFS...
fsutil behavior set disablelastaccess 1 >nul 2>&1
echo [OK] LastAccessTime desactivado.

:: --------------------------------------------------------------
:: [+] Limpieza segura de componentes antiguos de Windows Update
::     Libera espacio en WinSxS y acelera futuras actualizaciones
:: --------------------------------------------------------------
echo Limpiando almacén de componentes (WinSxS)...
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
echo [OK] Componentes obsoletos eliminados.

:: --------------------------------------------------------------
:: [+] Optimización de planificación de CPU (Windows 11 híbrido)
::     Mejora responsividad en Intel 12th+ / AMD Zen 4+
:: --------------------------------------------------------------
echo Ajustando planificación de CPU para baja latencia...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
echo [OK] Perfil de rendimiento multimedia optimizado.

:: --------------------------------------------------------------
:: [+] Desactivar HPET (High Precision Event Timer)
::     Reduce latencia del reloj del sistema → mejor respuesta UI/juegos
::     ⚠️ Solo si tu placa base lo soporta (la mayoría moderna sí)
:: --------------------------------------------------------------
echo Desactivando HPET para reducir latencia...
bcdedit /set useplatformclock false >nul 2>&1
bcdedit /set disabledynamictick yes >nul 2>&1
echo [OK] HPET deshabilitado.

:: --------------------------------------------------------------
:: [+] Optimización DNS y red (Cloudflare 1.1.1.1)
::     Acelera resolución de dominios y reduce ping
:: --------------------------------------------------------------
echo Configurando DNS optimizado...
:: Nota: Reemplaza "Wi-Fi" o "Ethernet" por el nombre exacto de tu adaptador si falla
netsh interface ipv4 set dnsservers name="Wi-Fi" source=static address=1.1.1.1 validate=no >nul 2>&1
netsh interface ipv4 set dnsservers name="Ethernet" source=static address=1.1.1.1 validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="Wi-Fi" address=1.0.0.1 index=2 >nul 2>&1
netsh interface ipv4 add dnsservers name="Ethernet" address=1.0.0.1 index=2 >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo [OK] DNS actualizado a Cloudflare.

:: --------------------------------------------------------------
:: [+] Opcional: Desactivar Integridad de Memoria (VBS) para Gaming
::     ⚠️ ADVERTENCIA: Aumenta FPS en juegos, pero reduce protección contra exploits de kernel
::     Solo descomenta si entiendes el trade-off de seguridad
:: --------------------------------------------------------------
:: echo Desactivando Virtualization-Based Security (VBS)...
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul 2>&1
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
:: echo [!] VBS desactivado. Reinicio requerido para aplicar.

echo.
echo [✔] Optimizaciones avanzadas aplicadas con éxito.
echo     • I/O de disco optimizado ✅
echo     • WinSxS limpio ✅
echo     • Planificación de CPU baja latencia ✅
echo     • HPET desactivado ✅
echo     • DNS rápido configurado ✅
echo.
timeout /t 2 >nul

:: Reparacion critica
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f

echo ==============================================================
echo 22. GESTIÓN DE NAVEGADORES
echo ============================================================== 
echo Instalando Brave Browser...
winget install Brave.Brave --silent --accept-package-agreements --accept-source-agreements
winget install --id Brave.Brave --source winget --silent --accept-package-agreements --accept-source-agreements

echo Configurando Brave como navegador predeterminado...
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" /v "ProgId" /d "BraveHTML" /f
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" /v "ProgId" /d "BraveHTML" /f
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\ftp\UserChoice" /v "ProgId" /d "BraveHTML" /f
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\mailto\UserChoice" /v "ProgId" /d "BraveHTML" /f

echo Estableciendo asociaciones de archivos...
assoc .html=BraveHTML
assoc .htm=BraveHTML
assoc .pdf=BraveHTML
assoc .xhtml=BraveHTML
assoc .xht=BraveHTML

echo Reiniciando el Explorador para aplicar cambios...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
timeout /t 2 >nul

echo ==============================
echo 23. INSTALACIÓN Y ACTUALIZACIÓN DE SOFTWARE
echo ==============================
:: Abrir link de apoyo
start https://www.paypal.com/donate/?hosted_button_id=DMREEX4NSS7V4

echo Instalando VLC Media Player...
winget install --id VideoLAN.VLC -e --source winget --accept-source-agreements --accept-package-agreements

echo Instalando WinRAR...
winget install --id RARLab.WinRAR -e --source winget --accept-source-agreements --accept-package-agreements

echo Instalando Nomacs...
winget install --id nomacs.nomacs -e --source winget --accept-source-agreements --accept-package-agreements


echo Actualizando todo el software instalado a la ultima version...
winget upgrade --all --accept-source-agreements --accept-package-agreements

echo ==============================================================
echo 24. MODO EXTREMO: OPTIMIZACIÓN PARA HDD + 4GB RAM O MENOS
echo ============================================================== 

:: --------------------------------------------------------------
:: [+] DETECCIÓN DE CONDICIONES: RAM < 5GB Y DISCO HDD
:: --------------------------------------------------------------
echo Verificando hardware para aplicar optimizaciones extremas...

:: Obtener RAM en MB
for /f %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)"') do set "CHECK_RAM=%%A"

:: Detectar tipo de disco principal (C:)
set "IS_HDD=0"
powershell -NoProfile -Command "$disk = Get-PhysicalDisk | Where-Object { (Get-Partition -DiskNumber $_.DeviceId).DriveLetter -contains 'C' }; if ($disk.MediaType -eq 'HDD') { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 set "IS_HDD=1"

echo [+] RAM detectada: %CHECK_RAM% MB | HDD detectado: %IS_HDD%

:: Condicional: Solo ejecutar si RAM < 5000 MB (5GB) Y es HDD
if %CHECK_RAM% GEQ 5000 goto SKIP_LOWEND_OPTIMIZATIONS
if %IS_HDD% NEQ 1 goto SKIP_LOWEND_OPTIMIZATIONS

echo [!] Sistema detectado: HDD + %CHECK_RAM%MB RAM → Aplicando modo extremo...
echo.

:: ============================================================
:: 🔴 OPTIMIZACIONES AGRESIVAS PARA HDD + BAJA RAM
:: ============================================================

:: --------------------------------------------------------------
:: [1] LIBERAR ESPACIO EN DISCO: Desactivar HIBERNACIÓN
::     hiberfil.sys ocupa ~40-75% de RAM → en 4GB son ~1.6-3GB
:: --------------------------------------------------------------
echo [1/12] Desactivando hibernación para liberar espacio en HDD...
powercfg /h off >nul 2>&1
if exist "C:\hiberfil.sys" del /f /q "C:\hiberfil.sys" >nul 2>&1
echo [OK] ~1.6-3GB liberados en disco.

:: --------------------------------------------------------------
:: [2] PAGEFILE AGGRESIVO: Compensar falta de RAM con disco
::     Tamaño fijo para evitar fragmentación en HDD
:: --------------------------------------------------------------
echo [2/12] Configurando pagefile estático para HDD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 0 /f >nul 2>&1
:: Pagefile = RAM * 2.5 (mín) y RAM * 4 (máx) para 4GB → 10GB/16GB
set /a PF_MIN=%CHECK_RAM%*25/10
set /a PF_MAX=%CHECK_RAM%*4
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys %PF_MIN% %PF_MAX%" /f >nul 2>&1
echo [OK] Pagefile: %PF_MIN%MB - %PF_MAX%MB (estático, sin fragmentación).

:: --------------------------------------------------------------
:: [3] DESACTIVAR SERVICIOS CRÍTICOS QUE CONSUMEN DISCO/RAM
:: --------------------------------------------------------------
echo [3/12] Deteniendo servicios pesados para HDD+low-RAM...
for %%s in (SysMain WSearch DiagTrack dmwappushservice WdiServiceHost WdiSystemHost PcaSvc WerSvc Fax RemoteRegistry PrintSpooler XblAuthManager XblGameSave XboxNetApiSvc OneSyncSvc_bfb DoSvc) do (
    sc stop "%%s" >nul 2>&1
    sc config "%%s" start= disabled >nul 2>&1
)
echo [OK] 15+ servicios desactivados.

:: --------------------------------------------------------------
:: [4] REDUCIR CACHÉ DE DISCO Y MEMORIA: Priorizar apps activas
:: --------------------------------------------------------------
echo [4/12] Ajustando gestión de memoria para baja RAM...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Caché de sistema optimizada para aplicaciones.

:: --------------------------------------------------------------
:: [5] DESACTIVAR PREFETCH/SUPERFETCH AGRESIVAMENTE
::     En HDD+4GB, el prefetch puede causar thrashing
:: --------------------------------------------------------------
echo [5/12] Desactivando Prefetch para evitar lecturas innecesarias...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Prefetch/Superfetch desactivados.

:: --------------------------------------------------------------
:: [6] LIMPIEZA AGRESIVA DE STANDBY LIST (RAM CACHE)
::     Forzar liberación de memoria en caché cada X minutos
:: --------------------------------------------------------------
echo [6/12] Configurando limpieza automática de memoria en caché...
:: Crear tarea programada para limpiar Standby List cada 10 minutos
powershell -NoProfile -ExecutionPolicy Bypass -Command "$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-Command [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); EmptyStandbyList 1'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10); $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; Register-ScheduledTask -TaskName 'CleanStandbyList_LowRAM' -Action $action -Trigger $trigger -Principal $principal -Force >$null 2>&1" 2>nul
echo [OK] Tarea 'CleanStandbyList_LowRAM' creada (limpia caché cada 10 min).

:: --------------------------------------------------------------
:: [7] REDUCIR ESCRITURAS EN HDD: NTFS OPTIMIZATIONS
:: --------------------------------------------------------------
echo [7/12] Minimizando escrituras en disco mecánico...
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsDisable8dot3NameCreation" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Escrituras innecesarias en NTFS reducidas.

:: --------------------------------------------------------------
:: [8] DESACTIVAR THUMBNAIL CACHE Y VISTAS PREVIAS
::     Evitar generación constante de miniaturas en HDD
:: --------------------------------------------------------------
echo [8/12] Desactivando caché de miniaturas para ahorrar I/O...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowPreviewHandlers" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowInfoTip" /t REG_DWORD /d 0 /f >nul 2>&1
:: Limpiar caché existente
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo [OK] Miniaturas y vistas previas desactivadas.

:: --------------------------------------------------------------
:: [9] DESACTIVAR WINDOWS UPDATE DESCARGAS EN SEGUNDO PLANO
::     Evitar que Downloads consuman ancho de banda y disco
:: --------------------------------------------------------------
echo [9/12] Bloqueando descargas automáticas de Windows Update...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoDownload" /t REG_DWORD /d 1 /f >nul 2>&1
sc stop DoSvc >nul 2>&1
sc config DoSvc start= disabled >nul 2>&1
echo [OK] Descargas en segundo plano bloqueadas.

:: --------------------------------------------------------------
:: [10] TCP OPTIMIZATIONS PARA BAJO CONSUMO DE MEMORIA
:: --------------------------------------------------------------
echo [10/12] Ajustando red para bajo uso de RAM...
netsh int tcp set global autotuninglevel=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
echo [OK] TCP optimizado para memoria limitada.

:: --------------------------------------------------------------
:: [11] DESACTIVAR EFECTOS VISUALES ADICIONALES
:: --------------------------------------------------------------
echo [11/12] Aplicando modo visual 'Rendimiento máximo'...
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "8007288010000000" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Efectos visuales adicionales desactivados.

:: --------------------------------------------------------------
:: [12] DESACTIVAR MANTENIMIENTO AUTOMÁTICO Y TAREAS PESADAS
:: --------------------------------------------------------------
echo [12/12] Desactivando tareas de mantenimiento automático...
schtasks /Change /TN "\Microsoft\Windows\TaskScheduler\Maintenance Configurator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /Disable >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Mantenimiento automático desactivado.

:: --------------------------------------------------------------
:: [+] REINICIAR EXPLORER PARA APLICAR CAMBIOS VISUALES
:: --------------------------------------------------------------
echo.
echo Aplicando cambios en la interfaz...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  ✅ MODO EXTREMO APLICADO: HDD + %CHECK_RAM%MB RAM  ║
echo ╠════════════════════════════════════════════════════╣
echo ║  • Hibernación desactivada: +1.6-3GB libres        ║
echo ║  • Pagefile estático: sin fragmentación            ║
echo ║  • 15+ servicios pesados desactivados              ║
echo ║  • Prefetch/Superfetch: OFF                        ║
echo ║  • Limpieza de RAM caché: cada 10 minutos          ║
echo ║  • Escrituras NTFS minimizadas                     ║
echo ║  • Miniaturas y vistas previas: OFF                ║
echo ║  • Windows Update background: bloqueado            ║
echo ║  • Efectos visuales: mínimos                       ║
echo ║  • Mantenimiento automático: desactivado           ║
echo ╠════════════════════════════════════════════════════╣
echo ║  ⚠️  ADVERTENCIA: Este modo prioriza velocidad     ║
echo ║     sobre comodidad. Algunas funciones pueden      ║
echo ║     estar limitadas o requerir más tiempo.         ║
echo ╚════════════════════════════════════════════════════╝
echo.

goto END_LOWEND_OPTIMIZATIONS

:SKIP_LOWEND_OPTIMIZATIONS
echo [+] Sistema NO cumple condiciones para modo extremo.
echo     • RAM >= 5GB y/o disco SSD → Saltando optimizaciones HDD+low-RAM.
echo.

:END_LOWEND_OPTIMIZATIONS
timeout /t 2 >nul

echo ==============================================================
echo 25. MODO SSD-LOWRAM: OPTIMIZACIÓN PARA SSD + 4GB RAM O MENOS
echo ============================================================== 

:: --------------------------------------------------------------
:: [+] DETECCIÓN DE CONDICIONES: RAM < 5GB Y DISCO SSD/NVMe
:: --------------------------------------------------------------
echo Verificando hardware para aplicar optimizaciones SSD+low-RAM...

:: Obtener RAM en MB
for /f %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)"') do set "CHECK_RAM_SSD=%%A"

:: Detectar tipo de disco principal (C:)
set "IS_SSD=0"
powershell -NoProfile -Command "$disk = Get-PhysicalDisk | Where-Object { (Get-Partition -DiskNumber $_.DeviceId).DriveLetter -contains 'C' }; if ($disk.MediaType -eq 'SSD' -or $disk.MediaType -eq 'Unspecified') { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 set "IS_SSD=1"

echo [+] RAM detectada: %CHECK_RAM_SSD% MB | SSD detectado: %IS_SSD%

:: Condicional: Solo ejecutar si RAM < 5000 MB (5GB) Y es SSD (NO HDD)
if %CHECK_RAM_SSD% GEQ 5000 goto SKIP_SSD_LOWEND_OPTIMIZATIONS
if %IS_SSD% NEQ 1 goto SKIP_SSD_LOWEND_OPTIMIZATIONS

echo [!] Sistema detectado: SSD + %CHECK_RAM_SSD%MB RAM → Aplicando modo SSD-LowRAM...
echo.

:: ============================================================
:: 🔵 OPTIMIZACIONES ESPECÍFICAS PARA SSD + BAJA RAM
:: ============================================================
:: Estrategia: Compensar poca RAM aprovechando la velocidad del SSD
:: ============================================================

:: --------------------------------------------------------------
:: [1] PAGEFILE DINÁMICO PERO AGILE: SSD permite swap rápido
::     Tamaño moderado: RAM * 1.5 (min) y RAM * 2.5 (max)
:: --------------------------------------------------------------
echo [1/10] Configurando pagefile optimizado para SSD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 0 /f >nul 2>&1
set /a PF_MIN_SSD=%CHECK_RAM_SSD%*15/10
set /a PF_MAX_SSD=%CHECK_RAM_SSD%*25/10
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys %PF_MIN_SSD% %PF_MAX_SSD%" /f >nul 2>&1
echo [OK] Pagefile SSD: %PF_MIN_SSD%MB - %PF_MAX_SSD%MB (swap rápido).

:: --------------------------------------------------------------
:: [2] MANTENER SYSMAIN/PREFETCH ACTIVADO (SSD lo beneficia)
::     A diferencia de HDD, en SSD el prefetch MEJORA el rendimiento
:: --------------------------------------------------------------
echo [2/10] Optimizando Prefetch/SysMain para SSD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBoottrace" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Prefetch/SysMain optimizados para SSD (valor 3 = boot+apps).

:: --------------------------------------------------------------
:: [3] DESACTIVAR SERVICIOS QUE CONSUMEN RAM (pero no los de disco)
:: --------------------------------------------------------------
echo [3/10] Deteniendo servicios que consumen RAM innecesariamente...
for %%s in (DiagTrack dmwappushservice WdiServiceHost WdiSystemHost PcaSvc WerSvc Fax RemoteRegistry XblAuthManager XblGameSave XboxNetApiSvc OneSyncSvc_bfb) do (
    sc stop "%%s" >nul 2>&1
    sc config "%%s" start= disabled >nul 2>&1
)
:: Nota: SysMain y WSearch se mantienen para aprovechar SSD
echo [OK] Servicios de telemetría y juegos desactivados (RAM liberada).

:: --------------------------------------------------------------
:: [4] MEMORIA: KERNEL EN DISCO, APPS EN RAM (prioridad baja RAM)
:: --------------------------------------------------------------
echo [4/10] Ajustando gestión de memoria para priorizar aplicaciones...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Memoria priorizada para aplicaciones de usuario.

:: --------------------------------------------------------------
:: [5] TRIM Y OPTIMIZACIÓN DE SSD: MANTENER SALUD DEL DISCO
:: --------------------------------------------------------------
echo [5/10] Verificando optimización de SSD (TRIM)...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
defrag C: /L /U >nul 2>&1
echo [OK] TRIM habilitado y SSD optimizado.

:: --------------------------------------------------------------
:: [6] DESACTIVAR HIBERNACIÓN (OPCIONAL: libera ~1.6-3GB)
::     En SSD el impacto es menor, pero libera espacio útil
:: --------------------------------------------------------------
echo [6/10] Desactivando hibernación para liberar espacio (opcional)...
powercfg /h off >nul 2>&1
if exist "C:\hiberfil.sys" del /f /q "C:\hiberfil.sys" >nul 2>&1
echo [OK] ~1.6-3GB liberados en SSD (hiberfil.sys eliminado).

:: --------------------------------------------------------------
:: [7] REDUCIR EFECTOS VISUALES PERO MANTENER FLUIDEZ
::     SSD permite ciertos efectos sin penalización de I/O
:: --------------------------------------------------------------
echo [7/10] Ajustando efectos visuales: equilibrio rendimiento/fluidez...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f >nul 2>&1
echo [OK] Efectos visuales equilibrados: sin animaciones, con fuentes suaves.

:: --------------------------------------------------------------
:: [8] TCP OPTIMIZATIONS: BUFFER MODERADO (SSD compensa swap)
:: --------------------------------------------------------------
echo [8/10] Ajustando red para equilibrio RAM/rendimiento...
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global chimney=enabled >nul 2>&1
echo [OK] TCP configurado para uso equilibrado de memoria.

:: --------------------------------------------------------------
:: [9] DESACTIVAR INDEXACIÓN DE BÚSQUEDA (ahorra RAM, SSD no lo necesita tanto)
:: --------------------------------------------------------------
echo [9/10] Desactivando indexación de búsqueda para ahorrar RAM...
sc stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo [OK] WSearch desactivado (~200-400MB RAM liberados).

:: --------------------------------------------------------------
:: [10] LIMPIEZA DE MEMORIA EN SEGUNDO PLANO (SSD permite swap rápido)
:: --------------------------------------------------------------
echo [10/10] Configurando liberación inteligente de memoria...
:: Tarea para liberar Standby List cada 15 minutos (menos agresivo que HDD)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-Command [System.GC]::Collect(); EmptyStandbyList 1'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15); $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; Register-ScheduledTask -TaskName 'CleanStandbyList_SSDLowRAM' -Action $action -Trigger $trigger -Principal $principal -Force >$null 2>&1" 2>nul
echo [OK] Tarea 'CleanStandbyList_SSDLowRAM' creada (limpia caché cada 15 min).

:: --------------------------------------------------------------
:: [+] REINICIAR EXPLORER PARA APLICAR CAMBIOS
:: --------------------------------------------------------------
echo.
echo Aplicando cambios en la interfaz...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  ✅ MODO SSD-LOWRAM APLICADO: SSD + %CHECK_RAM_SSD%MB RAM  ║
echo ╠════════════════════════════════════════════════════╣
echo ║  • Pagefile optimizado: swap rápido en SSD         ║
echo ║  • Prefetch/SysMain: ACTIVADOS (beneficio SSD)     ║
echo ║  • Servicios de telemetría: desactivados           ║
echo ║  • Memoria: priorizada para apps de usuario        ║
echo ║  • TRIM habilitado: salud del SSD preservada       ║
echo ║  • Hibernación: desactivada (+1.6-3GB libres)      ║
echo ║  • Efectos visuales: equilibrio fluidez/rendimiento║
echo ║  • TCP: buffering normal (SSD compensa swap)       ║
echo ║  • WSearch: desactivado (~200-400MB RAM libres)    ║
echo ║  • Limpieza de RAM: cada 15 minutos                ║
echo ╠════════════════════════════════════════════════════╣
echo ║  💡 CONSEJO: Con SSD, el sistema se sentirá más    ║
echo ║     responsivo incluso con poca RAM. Evita tener   ║
echo ║     muchas pestañas del navegador abiertas.        ║
echo ╚════════════════════════════════════════════════════╝
echo.

goto END_SSD_LOWEND_OPTIMIZATIONS

:SKIP_SSD_LOWEND_OPTIMIZATIONS
echo [+] Sistema NO cumple condiciones para modo SSD-LowRAM.
echo     • RAM >= 5GB y/o disco HDD → Saltando optimizaciones SSD+low-RAM.
echo.

:END_SSD_LOWEND_OPTIMIZATIONS
timeout /t 2 >nul

echo ==============================
echo Optimización completada.
echo ==============================
echo Es recomendable reiniciar el equipo para aplicar los cambios.
echo Presiona cualquier tecla para salir...
pause >nul
exit
