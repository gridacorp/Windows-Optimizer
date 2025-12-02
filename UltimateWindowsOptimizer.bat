@echo off
title Optimizador de Windows 11 - Optimización Integral
cls

echo ==============================
echo Iniciando optimización de Windows 11...
echo ==============================
timeout /t 3 >nul

echo ==============================================================
echo CREANDO PUNTO DE RESTAURACION DEL SISTEMA
echo ==============================================================

echo Comprobando y activando la Proteccion del Sistema en C:...
powershell -Command "Enable-ComputerRestore -Drive 'C:\\'" >nul 2>&1

echo Creando punto de restauracion antes de realizar los cambios...
powershell -Command "Checkpoint-Computer -Description 'Antes de optimizacion Windows 11' -RestorePointType MODIFY_SETTINGS" >nul 2>&1

if %errorlevel% equ 0 (
    echo.
    echo Punto de restauracion creado exitosamente.
) else (
    echo.
    echo ADVERTENCIA: No se pudo crear el punto de restauracion.
    echo.
    echo Causas comunes:
    echo  - La Proteccion del Sistema esta desactivada (aunque se intento activar).
    echo  - El sistema esta en una maquina virtual sin soporte completo.
    echo  - Politicas de grupo o antivirus estan bloqueando la funcion.
    echo.
    echo ^>^> Recomendacion: Activala manualmente:
    echo     1. Presiona Win + R, escribe "sysdm.cpl" y pulsa Enter.
    echo     2. Ve a la pestaña "Proteccion del sistema".
    echo     3. Selecciona la unidad C: y haz clic en "Configurar".
    echo     4. Marca "Activar la proteccion del sistema" y aplica.
    echo.
    echo Continuando en 5 segundos...
    timeout /t 5 >nul
)
timeout /t 3 >nul

echo ==============================================================
echo 00. DESACTIVAR BITLOCKER PARA MEJORAR RENDIMIENTO DE DISCO
echo ==============================================================

echo Verificando estado de BitLocker en la unidad C: ...

REM Buscar "Protección activada" (la salida en español)
manage-bde -status C: | findstr /i /c:"Protección activada"
set BITLOCKER_STATUS=%errorlevel%

if %BITLOCKER_STATUS% equ 0 (
    echo BitLocker está **ACTIVADO**. Iniciando desactivación...
    manage-bde -off C:
    if %errorlevel% equ 0 (
        echo La orden de desactivación se envió correctamente.
        echo BitLocker se está desactivando. Este proceso puede tardar varias horas dependiendo del tamaño del disco.
        echo **Los cambios se aplicarán completamente al reiniciar el sistema.**
    ) else (
        echo **ERROR:** Fallo al intentar ejecutar "manage-bde -off C:". **Asegúrese de ejecutar como administrador.**
    )
) else (
    echo BitLocker no está activado en la unidad C:, o no está disponible en esta edición de Windows.
    REM Un error de `manage-bde` (como no existir) también podría llevar a este bloque.
)
timeout /t 5 >nul

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
sc stop PcaSvc
sc config PcaSvc start= disabled
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
echo 5. GESTIÓN DE NAVEGADORES
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
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d 4 /f
echo Servicio de búsqueda desactivado completamente
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
echo Configurando distribucion de tiempo de CPU...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f
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
echo 18. Gestión inteligente de procesos
echo ============================================================== 
:: 1. LIMPIAR caché de sistema SIN riesgos
echo Limpiando caché de componentes de forma segura...
DISM /Online /Cleanup-Image /StartComponentCleanup >nul 2>&1

:: 2. DESACTIVAR SysMain en SSDs (mejora rendimiento real)
echo Desactivando SysMain para SSDs...
sc config "SysMain" start= disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1

:: 3. OPTIMIZAR Storage Sense (limpieza automatica segura)
echo Configurando Storage Sense optimizado...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 04 /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 20 /t REG_DWORD /d 1 /f >nul

:: 4. LIMITAR apps en segundo plano (ahorra RAM/CPU)
echo Limitando aplicaciones en segundo plano...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul

:: 5. ANALIZAR almacenamiento antes de limpiar
DISM /Online /Cleanup-Image /AnalyzeComponentStore >nul 2>&1

echo [OK] Gestion de procesos optimizada (segura y reversible).
timeout /t 2 >nul

echo ==============================================================
echo 19. DESHABILITAR O AJUSTAR SERVICIOS INNECESARIOS
echo ============================================================== 
echo Deshabilitando servicios innecesarios...
sc config Fax start= disabled
DISM /Online /Disable-Feature /FeatureName:FaxServicesClientPackage /NoRestart
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
echo Optimizando buffers TCP/IP
netsh int tcp set global rss=enabled
timeout /t 2 >nul
echo Deshabilitar IPv6
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 255 /f
echo Ajustar el algoritmo de congestión (por ejemplo, CTCP)
netsh int tcp set global congestionprovider=ctcp
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "AutoDetect" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f
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
echo 29. DESINSTALAR O DESHABILITAR WIDGETS Y XBOX (CMD SOLAMENTE)
echo ==============================
:: Desactivar Widgets desde el registro (barra de tareas)
echo Desactivando los Widgets desde la barra de tareas...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
:: Desactivar Widgets desde políticas (evita reinstalación)
echo Bloqueando Widgets mediante políticas...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f
:: Desinstalar Windows Web Experience Pack (Widgets backend)
echo Desinstalando Windows Web Experience Pack (Widgets)...
powershell -Command "Get-AppxPackage *WebExperience* | Remove-AppxPackage"
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

@echo off
title Eliminando Bloatware en Windows 11
cls

:: Verifica privilegios de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script debe ejecutarse como Administrador.
    pause
    exit /b
)

echo =============================================
echo 30. DESHABILITAR SERVICIOS INNECESARIOS
echo =============================================
echo Deshabilitando servicios innecesarios...

sc config DiagTrack start= disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1

sc config dmwappushservice start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1

sc config XblAuthManager start= disabled >nul 2>&1
sc stop XblAuthManager >nul 2>&1

sc config XblGameSave start= disabled >nul 2>&1
sc stop XblGameSave >nul 2>&1

sc config XboxNetApiSvc start= disabled >nul 2>&1
sc stop XboxNetApiSvc >nul 2>&1

sc config WdiServiceHost start= disabled >nul 2>&1
sc stop WdiServiceHost >nul 2>&1

sc config WdiSystemHost start= disabled >nul 2>&1
sc stop WdiSystemHost >nul 2>&1

echo Servicios desactivados.
echo.

echo =============================================
echo 31. DESHABILITAR WIDGETS Y COMPONENTES LIGEROS
echo =============================================
echo Deshabilitando Widgets y WebExperience...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f
powershell -Command "Get-AppxPackage *WebExperience* | Remove-AppxPackage"
echo Widgets eliminados.
echo.

echo =============================================
echo 32. OPTIMIZAR EFECTOS VISUALES (SIN BORRAR FONDO)
echo =============================================
echo Aplicando tema visual ligero (transparencia y animaciones)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v FolderType /t REG_SZ /d NotSpecified /f
echo Tema visual optimizado. El fondo de pantalla no se modifica.
echo.

echo =============================================
echo 33. LIMPIAR PROGRAMAS DE INICIO AUTOMÁTICO
echo =============================================
echo Limpiando inicio automático innecesario...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /f >nul 2>&1
echo Programas de inicio limpiados.
echo.

echo =============================================
echo 34. FORZAR USO DE HIBERNACIÓN EN LUGAR DE SUSPENSIÓN
echo =============================================
echo Activando hibernación como modo preferido de reposo...
powercfg -hibernate on
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
echo Hibernación activada.
echo.

echo =============================================
echo 35. Para equipos con menos de 8 GB de 
echo =============================================
REM Obtener la cantidad de RAM en MB
for /f %%A in ('powershell -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)" 2^>^&1') do set RAM_MB=%%A

REM Verificar si la obtención de RAM fue exitosa
if "%RAM_MB%"=="" (
    echo ERROR: No se pudo determinar la cantidad de RAM del sistema.
    echo El script se ejecutara como medida de seguridad.
    timeout /t 3 >nul
    goto continue_optimization
)

REM Convertir RAM a número y comparar
set /a RAM_NUM=%RAM_MB% 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Valor de RAM invalido.
    echo El script se ejecutara como medida de seguridad.
    timeout /t 3 >nul
    goto continue_optimization
)

REM Verificar si la RAM es menor a 8GB (8192 MB)
if %RAM_NUM% geq 8192 (
    echo ======================================================
    echo SISTEMA CON %RAM_NUM% MB DE RAM (%RAM_NUM% GB)
    echo ======================================================
    echo.
    echo Este optimizador esta disenado EXCLUSIVAMENTE para 
    echo equipos con MENOS de 8 GB de RAM.
    echo.
    echo Tu sistema tiene RAM suficiente para funcionar bien
    echo con la configuracion predeterminada de Windows 11.
    echo.
    echo ^>^> NO SE REALIZARA NINGUN CAMBIO EN TU SISTEMA ^<^<
    echo.
    echo Recomendaciones para tu sistema:
    echo - Manten Windows actualizado
    echo - Usa el plan de energia "Equilibrado" (predeterminado)
    echo - No desactives servicios criticos como SysMain
    echo.
    echo Presiona cualquier tecla para salir...
    pause >nul
    exit
)

:continue_optimization
echo ======================================================
echo SISTEMA CON %RAM_NUM% MB DE RAM (%RAM_NUM% GB)
echo OPTIMIZACION MAXIMA RENDIMIENTO ACTIVADA
echo ======================================================
timeout /t 3 >nul

REM 1. Configurar pagefile ADECUADO para poca RAM
set /a MIN_SIZE=%RAM_NUM%
set /a MAX_SIZE=%RAM_NUM%*2

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys %MIN_SIZE% %MAX_SIZE%" /f >nul

REM 2. DESACTIVAR EFECTOS VISUALES (ahorra RAM y CPU)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul

REM 3. DESACTIVAR SERVICIOS CONSUMIDORES DE RAM
sc config SysMain start= disabled >nul
sc config WSearch start= disabled >nul  
sc config DiagTrack start= disabled >nul
sc config dmwappushservice start= disabled >nul

REM 4. ELIMINAR BLOATWARE CRÍTICO (ahorra RAM en segundo plano)
powershell -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *WindowsStore* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *OneDrive* | Remove-AppxPackage" >nul 2>&1

REM 5. OPTIMIZAR MEMORIA DEL SISTEMA
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul

REM 6. ¡¡¡CAMBIO CRUCIAL!!! - FORZAR ALTO RENDIMIENTO
powercfg -setactive SCHEME_MAX >nul
echo =============================================
echo OPTIMIZACION COMPLETADA - ALTO RENDIMIENTO
echo =============================================

echo ============================================
echo 36. Reparacion de Disco Duro y Sectores
echo ============================================
echo Y | chkdsk C: /F /R /X
echo S | chkdsk C: /F /R /X
echo ============================================
echo CHKDSK se ejecuto y quedo programado.
echo ============================================

echo ==============================
echo 37. Para equipos con MAS de 8 GB de RAM
echo ==============================
echo Verificando cantidad de memoria RAM...
for /f "tokens=2 delims==" %%a in ('wmic ComputerSystem get TotalPhysicalMemory /value ^| find "="') do set TotalRAM=%%a
set /a TotalRAMGB=%TotalRAM% / 1073741824

echo Cantidad total de RAM detectada: %TotalRAMGB% GB

if %TotalRAMGB% leq 8 (
    echo.
    echo ERROR: Este optimizador esta disenado SOLO para equipos con MAS DE 8 GB de RAM.
    echo Tu sistema tiene %TotalRAMGB% GB de RAM, que no cumple con el requisito minimo.
    echo.
    echo Recomendacion: Usa una version optimizada para sistemas con 8GB o menos de RAM.
    echo.
    pause
    exit /b 1
)

echo ==============================
echo Sistema cumple con requisitos (mas de 8GB RAM)
echo Iniciando optimizacion...
echo ==============================
timeout /t 3 >nul

REM Detectar si es SSD para optimizaciones específicas
wmic diskdrive where "MediaType='SSD'" get DeviceID | findstr /i "SSD" >nul && set SSD=1 || set SSD=0

echo ==============================================================
echo OPTIMIZACION DE MEMORIA PARA 8GB+ RAM
echo ==============================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IoPageLockLimit" /t REG_DWORD /d 262144 /f

echo ==============================================================
echo OPTIMIZACION DE CPU PARA BAJO LATENCIA
echo ==============================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableDynamicTick" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "ClockInterruptsPerSecond" /t REG_DWORD /d 1024 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f

echo ==============================================================
echo SERVICIOS QUE CAUSAN MICRO-STUTTERS (desactivar)
echo ==============================================================
sc config Audiosrv start= disabled >nul 2>&1
sc config AudioEndpointBuilder start= disabled >nul 2>&1
sc config MMCSS start= disabled >nul 2>&1
sc config Themes start= disabled >nul 2>&1
sc config UxSms start= disabled >nul 2>&1
sc config Sens start= disabled >nul 2>&1

echo ==============================================================
echo OPTIMIZACION DE GPU PARA GAMING
echo ==============================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnablePreemption" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "D3D12Enable" /t REG_DWORD /d 1 /f

REM Solo desactivar SysMain si es SSD
if "%SSD%"=="1" (
    echo Sistema detectado como SSD - Desactivando SysMain...
    sc config SysMain start= disabled
    sc stop SysMain
)

echo ==============================================================
echo OPTIMIZACION DE RED PARA BAJA LATENCIA
echo ==============================================================
netsh int tcp set global autotuninglevel=experimental
netsh int tcp set global ecncapability=disabled
netsh int tcp set global rss=enabled
netsh int ip set global taskoffload=disabled

echo ==============================
echo Optimizacion completada para sistema de 8GB+ RAM
echo Reinicio recomendado para aplicar todos los cambios
echo ==============================

echo ==============================
echo 38. Eliminando Bloatware...
echo ==============================

echo ----- Bloqueando reinstalación -----
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f

echo ----- Eliminando Game Bar desde políticas -----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

:: Ejecutar PowerShell desde CMD para desinstalar apps
powershell -Command "Get-AppxPackage *3DBuilder* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *ZuneMusic* | Remove-AppxPackage"      :: Groove Música
powershell -Command "Get-AppxPackage *ZuneVideo* | Remove-AppxPackage"      :: Películas y TV
powershell -Command "Get-AppxPackage *XboxApp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.XboxGamingOverlay* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.Xbox.TCUI* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.XboxGameOverlay* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.BingNews* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.GetHelp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.Getstarted* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.MicrosoftSolitaireCollection* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.People* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.SkypeApp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.MicrosoftOfficeHub* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.Todos* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.WindowsAlarms* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.WindowsFeedbackHub* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.WindowsMaps* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.WindowsSoundRecorder* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.YourPhone* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.MicrosoftStickyNotes* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.OneConnect* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.Wallet* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *XboxGamingOverlay* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *XboxGameCallableUI* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *XboxIdentityProvider* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.GamingApp* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *XboxSpeechToTextOverlay* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.Xbox.TCUI* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.XboxGameOverlay* | Remove-AppxPackage"
powershell -Command "Get-AppxPackage *Microsoft.XboxGamingOverlay* | Remove-AppxPackage"

echo ----------------------------
echo Bloatware eliminado.
echo ----------------------------

echo ==============================
echo 39. ACTUALIZAR TODO EL SOFTWARE
echo ==============================
start https://www.paypal.com/donate/?hosted_button_id=DMREEX4NSS7V4
winget upgrade --all

echo ==============================
echo Optimización completada.
echo ==============================
echo Es recomendable reiniciar el equipo para aplicar los cambios.
echo Presiona cualquier tecla para salir...
pause >nul
exit
