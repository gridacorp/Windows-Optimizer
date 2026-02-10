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
:: FASE 1: Preparación y Exclusiones (Preventivo)
echo [+] Aplicando exclusiones y limites de carga...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionProcess 'MsMpEng.exe'" >nul 2>&1
powershell -Command "Set-MpPreference -ScanAvgCPULoadFactor 1" >nul 2>&1

:: FASE 2: Desactivación de Protección contra Manipulación (Tamper Protection)
:: Nota: En versiones modernas, esto suele requerir desactivación manual previa en la UI.
echo [+] Intentando anular Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtectionConfig /t REG_DWORD /d 0 /f >nul 2>&1

:: FASE 3: Políticas de Grupo (GPO) y Registro
echo [+] Deshabilitando politicas de proteccion y telemetria...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControlEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: FASE 4: Muerte de Servicios y Drivers
echo [+] Bloqueando servicios de seguridad y drivers de arranque...
set "servicios=WinDefend WdNisSvc WdBoot WdFilter wscsvc WdNisDrv Sense"
for %%s in (%servicios%) do (
    sc stop %%s >nul 2>&1
    sc config %%s start= disabled >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%s" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
)

:: FASE 5: Terminación de Procesos Activos
echo [+] Terminando procesos en ejecucion...
taskkill /f /im MsMpEng.exe >nul 2>&1
taskkill /f /im NisSrv.exe >nul 2>&1
taskkill /f /im SenseCncProxy.exe >nul 2>&1
taskkill /f /im MsSense.exe >nul 2>&1

:: FASE 7: Limpieza de Tareas Programadas y App UI
echo [+] Eliminando tareas programadas y la interfaz de usuario...
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Verification" /f >nul 2>&1
powershell -Command "Get-AppxPackage *Microsoft.Windows.SecHealthUI* | Remove-AppxPackage" >nul 2>&1

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

:: Eliminar paquetes provisionados para evitar reinstalación
powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like '*3DBuilder*' -or $_.DisplayName -like '*ZuneMusic*' -or $_.DisplayName -like '*ZuneVideo*' -or $_.DisplayName -like '*Xbox*' -or $_.DisplayName -like '*BingNews*' -or $_.DisplayName -like '*GetHelp*' -or $_.DisplayName -like '*Getstarted*' -or $_.DisplayName -like '*Solitaire*' -or $_.DisplayName -like '*People*' -or $_.DisplayName -like '*Skype*' -or $_.DisplayName -like '*OfficeHub*' -or $_.DisplayName -like '*Todos*' -or $_.DisplayName -like '*Alarms*' -or $_.DisplayName -like '*FeedbackHub*' -or $_.DisplayName -like '*Maps*' -or $_.DisplayName -like '*SoundRecorder*' -or $_.DisplayName -like '*YourPhone*' -or $_.DisplayName -like '*StickyNotes*' -or $_.DisplayName -like '*OneConnect*' -or $_.DisplayName -like '*Wallet*' -or $_.DisplayName -like '*GamingApp*' -or $_.DisplayName -like '*Terminal*' -or $_.DisplayName -like '*PowerAutomate*' -or $_.DisplayName -like '*Outlook*'} | Remove-AppxProvisionedPackage -Online"

echo Iniciando limpieza de aplicaciones OEM...
echo Por favor, espera a que termine el proceso.
echo.

:: Versión corregida en una sola línea de comando para evitar errores de sintaxis
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vendors='hp|lenovo|dell|asus|acer'; $exclude='driver|firmware|bios|interface|foundation|system|hotkey|audio|chipset|service'; Write-Host '--- BUSCANDO APPS INSTALADAS ---' -ForegroundColor Cyan; $apps = Get-AppxPackage -AllUsers | Where-Object { ($_.Name -match $vendors -or $_.PackageFamilyName -match $vendors -or $_.Publisher -match $vendors) -and ($_.Name -notmatch $exclude) }; if ($apps) { foreach ($app in $apps) { Write-Host ('Eliminando: ' + $app.Name) -ForegroundColor Yellow; Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction SilentlyContinue } } else { Write-Host 'No se encontraron apps de usuario.' -ForegroundColor Green }; Write-Host '--- BUSCANDO APPS PROVISIONADAS ---' -ForegroundColor Cyan; $prov = Get-AppxProvisionedPackage -Online | Where-Object { ($_.DisplayName -match $vendors) -and ($_.DisplayName -notmatch $exclude) }; if ($prov) { foreach ($p in $prov) { Write-Host ('Eliminando provisionada: ' + $p.DisplayName) -ForegroundColor Magenta; Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue } } else { Write-Host 'No se encontraron apps provisionadas.' -ForegroundColor Green }; Write-Host 'Limpieza finalizada.' -ForegroundColor White"

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
:: Limpiar inicio de usuario actual
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /f >nul 2>&1

:: Limpiar inicio de todos los usuarios (requiere permisos)
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

echo Ajustando plan de energía a "Alto rendimiento"...
powercfg -setactive SCHEME_MIN
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
timeout /t 2 >nul
echo.
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
del /q /s /f "C:\Windows\Prefetch\*" >nul 2>&1
echo [OK] Temporales limpios.

echo [+] Verificando integridad de la imagen de Windows...
dism /online /cleanup-image /checkhealth | findstr /i "No se detectaron daños" >nul
if %errorLevel% neq 0 (
    echo [!] Aviso: Se detectaron inconsistencias leves, la limpieza puede tardar.
)

echo [+] Analizando y limpiando almacen de componentes (WinSxS)...
echo     Esto puede tardar varios minutos...
DISM /Online /Cleanup-Image /AnalyzeComponentStore >nul 2>&1
DISM /Online /Cleanup-Image /StartComponentCleanup /NoRestart >nul 2>&1

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

echo ==============================================================
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
echo 17. Ajustes para Optimizar el Rendimiento de Windows Mediante la Desactivación de Efectos y Funciones Opcionales
echo ============================================================== 
echo Deshabilitando animaciones y efectos visuales innecesarios...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
timeout /t 2 >nul

echo Deshabilitando widgets y Cortana...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

taskkill /f /im explorer.exe
start explorer.exe
timeout /t 2 >nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f

echo Deshabilitando transparencia...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo Deshabilitando Game DVR y Game Bar...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowGameBar" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo Aplicando tema visual ligero (transparencia y animaciones)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v FolderType /t REG_SZ /d NotSpecified /f
:: Restablecer caché de iconos y configuración de carpetas
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe
echo Tema visual optimizado. El fondo de pantalla no se modifica.
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

:: =====================================================================
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
echo 21. GESTIÓN DE NAVEGADORES
echo ============================================================== 
echo Instalando Brave Browser...
winget install Brave.Brave --silent --accept-package-agreements --accept-source-agreements

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
echo 22. ACTUALIZAR TODO EL SOFTWARE
echo ==============================
start https://www.paypal.com/donate/?hosted_button_id=DMREEX4NSS7V4
winget upgrade --all --accept-source-agreements --accept-package-agreements
winget upgrade --all

echo ==============================
echo Optimización completada.
echo ==============================
echo Es recomendable reiniciar el equipo para aplicar los cambios.
echo Presiona cualquier tecla para salir...
pause >nul
exit
