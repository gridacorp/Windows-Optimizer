@echo off
title Optimizador de Windows 11 - Optimización Integral
cls

echo ==============================
echo Iniciando optimización de Windows 11...
echo ==============================
timeout /t 3 >nul

echo ==============================================================
echo 1. DESACTIVAR EFECTOS VISUALES Y ANIMACIONES
echo ============================================================== 
echo Deshabilitando animaciones y efectos visuales innecesarios...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
timeout /t 2 >nul

echo ==============================================================
echo 2. BLOQUEAR TELEMETRÍA Y RECOLECCIÓN DE DATOS
echo ============================================================== 
echo Bloqueando telemetría y recopilacion de datos...
sc stop DiagTrack
sc config DiagTrack start= disabled
sc stop dmwappushservice
sc config dmwappushservice start= disabled
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
timeout /t 2 >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
echo Desactivando servicios de telemetría...
sc stop DiagTrack
sc config DiagTrack start= disabled
sc stop dmwappushservice
sc config dmwappushservice start= disabled
sc stop WdiServiceHost
sc config WdiServiceHost start= disabled
sc stop NlaSvc
sc config NlaSvc start= disabled
sc stop PcaSvc
sc config PcaSvc start= disabled
sc stop Wecsvc
sc config Wecsvc start= disabled
sc stop WerSvc
sc config WerSvc start= disabled

echo ==============================================================
echo 3. CONFIGURAR ACTUALIZACIONES AUTOMÁTICAS (SOLO ACUMULATIVAS)
echo ============================================================== 
echo Configurando actualizaciones automáticas (modo manual)...
sc stop wuauserv
sc config wuauserv start= demand
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 4. OPTIMIZAR EL ARRANQUE
echo ============================================================== 
echo Optimizando arranque...
bcdedit /set {current} numproc %NUMBER_OF_PROCESSORS%
bcdedit /set {current} useplatformclock false
bcdedit /set {current} disabledynamictick yes
timeout /t 2 >nul

echo ==============================================================
echo 5. GESTIÓN DE MICROSOFT EDGE
echo ============================================================== 
setlocal
rem Obtiene la versión instalada de Microsoft Edge
for /f "tokens=3" %%v in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon" /v version') do set EDGE_VERSION=%%v
rem Ruta del instalador de Edge
set INSTALLER_PATH=%PROGRAMFILES(X86)%\Microsoft\Edge\Application\%EDGE_VERSION%\Installer
rem Desinstala Microsoft Edge
"%INSTALLER_PATH%\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
endlocal

title Eliminar Microsoft Edge
cls

echo Eliminando Microsoft Edge completamente...
echo Cerrar Microsoft Edge si está en ejecución
taskkill /f /im msedge.exe

echo Eliminar carpeta de instalación de Edge
rmdir /s /q "C:\Program Files (x86)\Microsoft\Edge"
rmdir /s /q "C:\Program Files\Microsoft\Edge"

echo Eliminar las carpetas de perfil y datos
rmdir /s /q "%localappdata%\Microsoft\Edge"
rmdir /s /q "%appdata%\Microsoft\Edge"

echo Eliminar las claves del registro de Edge
reg delete "HKCU\Software\Microsoft\Edge" /f
reg delete "HKLM\Software\Microsoft\Edge" /f
reg delete "HKLM\Software\Policies\Microsoft\Edge" /f

timeout /t 2 >nul

echo Microsoft Edge ha sido completamente eliminado.

:: DESINSTALAR MICROSOFT EDGE
echo ==============================
echo Eliminando Microsoft Edge...
echo ==============================
timeout /t 2 >nul
cd %PROGRAMFILES(X86)%\Microsoft\Edge\Application\*
for /d %%F in (9*) do cd %%F\Installer & setup.exe --uninstall --system-level --verbose-logging --force-uninstall

echo ==============================
echo Microsoft Edge ha sido eliminado.
echo ==============================
timeout /t 2 >nul

echo ==============================================================
echo 6. DESHABILITAR WIDGETS Y CORTANA
echo ============================================================== 
echo Deshabilitando widgets y Cortana...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

taskkill /f /im explorer.exe
start explorer.exe
timeout /t 2 >nul

if exist "%ProgramFiles(x86)%\Microsoft\Edge" rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge"

taskkill /f /im msedge.exe
if exist "%ProgramFiles(x86)%\Microsoft\Edge" rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge"
if exist "%ProgramFiles%\Microsoft\Edge" rd /s /q "%ProgramFiles%\Microsoft\Edge"
if exist "%LocalAppData%\Microsoft\Edge" rd /s /q "%LocalAppData%\Microsoft\Edge"
timeout /t 2 >nul

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f

echo ==============================================================
echo 7. DESHABILITAR TRANSPARENCIA (FLUENT DESIGN)
echo ============================================================== 
echo Deshabilitando transparencia...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo ==============================================================
echo 8. DESHABILITAR APLICACIONES DE INICIO Y PROCESOS EN SEGUNDO PLANO
echo ============================================================== 
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
echo 9. DESACTIVAR INDEXACIÓN DE BÚSQUEDA
echo ============================================================== 
echo Desactivando indexación de búsqueda...
sc stop "WSearch"
sc config "WSearch" start= disabled || echo No se pudo detener el servicio WSearch
timeout /t 2 >nul

echo ==============================================================
echo 10. AJUSTAR PLAN DE ENERGÍA A "ALTO RENDIMIENTO"
echo ============================================================== 
echo Ajustando plan de energía a "Alto rendimiento"...
powercfg -setactive SCHEME_MIN
timeout /t 2 >nul

echo ==============================================================
echo 11. DESHABILITAR GAME DVR Y GAME BAR
echo ============================================================== 
echo Deshabilitando Game DVR y Game Bar...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameBar" /v "AllowGameBar" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo ==============================================================
echo 12. HABILITAR EL MODO DE JUEGOS
echo ============================================================== 
echo Habilitando Modo de Juegos...
reg add "HKCU\System\GameConfigStore" /v "GameModeEnabled" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 13. AJUSTAR ESCALADO DE GPU PARA MEJOR RENDIMIENTO
echo ============================================================== 
echo Ajustando escalado de GPU para mejor rendimiento...
echo Nota: Este ajuste depende del hardware y drivers instalados.
reg add "HKCU\Software\Microsoft\DirectX" /v "EnableGPUScaling" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 14. OPTIMIZAR PRIORIDAD DEL PROCESADOR PARA APLICACIONES ACTIVAS
echo ============================================================== 
echo Ajustando prioridad del procesador para aplicaciones activas...
wmic process where "name='explorer.exe'" call setpriority 128
wmic process where "name='notepad.exe'" call setpriority 128
wmic process where "name='chrome.exe'" call setpriority 128
timeout /t 2 >nul

echo ==============================================================
echo 15. DESACTIVAR RECOLECCIÓN ADICIONAL DE DATOS DE DIAGNÓSTICO
echo ============================================================== 
echo Desactivando recolección adicional de datos de diagnóstico...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo ==============================================================
echo 16. DESHABILITAR PERMISOS DE APLICACIONES INNECESARIAS
echo ============================================================== 
echo Deshabilitando permisos de aplicaciones innecesarias...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\camera" /v "Value" /t REG_SZ /d "Deny" /f
timeout /t 2 >nul

echo ==============================================================
echo 17. DESHABILITAR LÍMITE DE ANCHO DE BANDA DE WINDOWS UPDATE
echo ============================================================== 
echo Deshabilitando límite de ancho de banda de Windows Update...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "NoBandwidthThrottling" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 18. OPTIMIZAR BUFFERS TCP/IP Y DESHABILITAR AUTOAJUSTE DE VENTANA TCP
echo ============================================================== 
echo Optimizando buffers TCP/IP y deshabilitando autoajuste de ventana TCP...
netsh int tcp set global autotuninglevel=disabled
netsh int tcp set global rss=enabled
timeout /t 2 >nul

echo ==============================================================
echo 19. DESHABILITAR O AJUSTAR SERVICIOS INNECESARIOS
echo ============================================================== 
echo Deshabilitando servicios innecesarios...
sc config Fax start= disabled
sc config RemoteRegistry start= disabled
taskkill /f /im OneDrive.exe
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSync" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 20. DESACTIVAR SINCRONIZACIÓN DE APLICACIONES Y NOTIFICACIONES
echo ============================================================== 
echo Deshabilitando sincronización de aplicaciones y notificaciones...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo ==============================================================
echo 21. HABILITAR ACELERACIÓN DE GPU POR HARDWARE
echo ============================================================== 
echo Habilitando aceleración de GPU por hardware (verifique compatibilidad)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f
timeout /t 2 >nul

echo ==============================================================
echo 22. AJUSTES AVANZADOS DE RED
echo ============================================================== 
echo Ajustando configuraciones avanzadas de red...
echo Opcional: Deshabilitar IPv6 (puede afectar conexiones en ciertos entornos)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 255 /f
echo Ajustar el algoritmo de congestión (por ejemplo, CTCP)
netsh int tcp set global congestionprovider=ctcp
timeout /t 2 >nul

echo ==============================================================
echo 23. DESHABILITAR ACTUALIZACIONES AUTOMÁTICAS DE DRIVERS Y WINDOWS STORE
echo ============================================================== 
echo Deshabilitando actualizaciones automáticas de drivers y de Windows Store...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f
timeout /t 2 >nul

echo ==============================================================
echo 24. DESHABILITAR STORAGE SENSE
echo ============================================================== 
echo Deshabilitando Storage Sense...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "DisableStorageSense" /t REG_DWORD /d 1 /f
timeout /t 2 >nul

echo ==============================================================
echo 25. DESHABILITAR TAREAS PROGRAMADAS INNECESARIAS
echo ============================================================== 
echo Deshabilitando tareas programadas innecesarias...
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
echo Puedes agregar más tareas según tus necesidades.
timeout /t 2 >nul

echo ==============================================================
echo 26. DESACTIVAR NOTIFICACIONES, SUGERENCIAS Y ANUNCIOS
echo ============================================================== 
echo Desactivando notificaciones, sugerencias y anuncios...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo ==============================================================
echo 27. MEMORIA RAM
echo ============================================================== 
@echo off
REM Este script debe ejecutarse como administrador

echo Obteniendo la memoria física instalada...
for /f "skip=1 tokens=1" %%a in ('wmic computersystem get TotalPhysicalMemory') do (
    set RAM_BYTES=%%a
    goto Calcula
)
:Calcula
REM Convertir de bytes a megabytes (1 MB = 1048576 bytes)
set /a RAM_MB=%RAM_BYTES%/1048576
echo Memoria instalada: %RAM_MB% MB

REM Calcular el tamaño mínimo (1.5 * RAM) y máximo (3 * RAM)
set /a MIN_SIZE=(RAM_MB*3)/2
set /a MAX_SIZE=RAM_MB*3

echo Tamaño de archivo de paginacion:
echo  Mínimo: %MIN_SIZE% MB
echo  Máximo: %MAX_SIZE% MB

echo Desactivando la administracion automatica del archivo de paginacion...
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False

echo Configurando el archivo de paginacion en C:\pagefile.sys...
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=%MIN_SIZE%,MaximumSize=%MAX_SIZE%

echo ==============================================================
echo 28. DEFENDER
echo ============================================================== 

reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f
sc stop WinDefend
sc config WinDefend start= disabled

REM Este script debe ejecutarse como administrador

echo Deshabilitando funciones de Microsoft Defender...

REM Deshabilitar Protección en tiempo real
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f

REM Deshabilitar Protección contra Manipulación
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f

REM Deshabilitar Protección basada en la nube
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableCloudProtection /t REG_DWORD /d 1 /f

REM Deshabilitar Envío de muestras automático
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f

REM Deshabilitar Protección de la unidad para desarrolladores
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f

REM Deshabilitar Antivirus
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v DisableAntivirus /t REG_DWORD /d 1 /f

REM Detener el servicio de Windows Defender
sc stop WinDefend

REM Deshabilitar el inicio automático del servicio de Windows Defender
sc config WinDefend start= disabled

echo Funciones de Windows Defender deshabilitadas. Es posible que necesites reiniciar el equipo para que los cambios surtan efecto.

echo ==============================
echo 30. ACTUALIZAR TODO EL SOFTWARE
echo ==============================
winget upgrade --all


echo ==============================
echo 29. DESINSTALAR O DESHABILITAR WIDGETS Y XBOX (CMD SOLAMENTE)
echo ==============================

:: Desactivar Widgets desde el registro
echo Desactivando los Widgets...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f

:: Reiniciar el Explorador para aplicar el cambio
echo Reiniciando el Explorador de Windows...
taskkill /f /im explorer.exe
start explorer.exe

:: Intentar quitar apps UWP usando DISM (requiere permisos de admin)
echo Intentando quitar paquetes preinstalados de Xbox...
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.XboxGamingOverlay_*
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.XboxGameCallableUI_*
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.XboxIdentityProvider_*
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.GamingApp_*

timeout /t 2 >nul

echo ==============================
echo Optimización completada.
echo ==============================
echo Presiona cualquier tecla para salir...
pause >nul
exit
