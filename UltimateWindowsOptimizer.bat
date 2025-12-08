@echo off
title Optimizador de Windows 11 - Optimización Integral
cls

echo ==============================
echo Iniciando optimización de Windows 11...
echo ==============================
timeout /t 3 >nul

echo ==============================================================
echo 01. CREANDO PUNTO DE RESTAURACION DEL SISTEMA
echo ==============================================================

echo Comprobando y activando la Proteccion del Sistema en C:...
powershell -Command "Enable-ComputerRestore -Drive 'C:\\'" >nul 2>&1
powershell -ExecutionPolicy Bypass -Command "Enable-ComputerRestore -Drive 'C:\\'" >nul 2>&1

echo Creando punto de restauracion antes de realizar los cambios...
powershell -Command "Checkpoint-Computer -Description 'Antes de optimizacion Windows 11' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Antes de optimizacion Windows 11' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop" >nul 2>&1

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
echo 02. DESACTIVAR BITLOCKER PARA MEJORAR RENDIMIENTO DE DISCO
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
echo 03. DEFENDER
echo ============================================================== 
REM Deshabilitar Protección contra Manipulación (TamperProtection)
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtectionConfig /t REG_DWORD /d 0 /f >nul 2>&1

REM Detener y deshabilitar el servicio principal de Defender
sc stop WinDefend >nul 2>&1
timeout /t 2 /nobreak >nul
sc config WinDefend start= disabled >nul 2>&1

REM Deshabilitar Protección en tiempo real
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1

REM Deshabilitar Protección basada en la nube
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableCloudProtection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul 2>&1

REM Deshabilitar Envío de muestras automático
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul 2>&1

REM Deshabilitar componentes adicionales de Windows 11
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access" /v EnableControlledFolderAccess /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControlEnabled /t REG_DWORD /d 0 /f >nul 2>&1

REM Deshabilitar servicios relacionados adicionales en Windows 11
sc stop WdNisSvc >nul 2>&1
sc config WdNisSvc start= disabled >nul 2>&1
sc stop WdBoot >nul 2>&1
sc config WdBoot start= disabled >nul 2>&1
sc stop WdFilter >nul 2>&1
sc config WdFilter start= disabled >nul 2>&1
sc stop WdNisDrv >nul 2>&1
sc config WdNisDrv start= disabled >nul 2>&1

REM Forzar la terminación de procesos de Defender en Windows 11
taskkill /f /im MsMpEng.exe >nul 2>&1
taskkill /f /im NisSrv.exe >nul 2>&1
taskkill /f /im SenseCncProxy.exe >nul 2>&1

echo Funciones de Windows Defender deshabilitadas. Es posible que necesites reiniciar el equipo para que los cambios surtan efecto.

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
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.3DBuilder* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.ZuneMusic* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.ZuneVideo* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.XboxApp* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.XboxGameOverlay* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.Xbox.TCUI* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.BingNews* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.GetHelp* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.Getstarted* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.MicrosoftSolitaireCollection* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.People* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.SkypeApp* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.MicrosoftOfficeHub* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.Todos* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsAlarms* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsFeedbackHub* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsMaps* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsSoundRecorder* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.YourPhone* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.StickyNotes* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.MicrosoftStickyNotes* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.OneConnect* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.Wallet* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.GamingApp* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.XboxIdentityProvider* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.Windows.Photos* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsCamera* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsCommunicationsApps* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsTerminal* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.PowerAutomateDesktop* | Remove-AppxPackage -AllUsers"
powershell -Command "Get-AppxPackage -AllUsers *Microsoft.OutlookForWindows* | Remove-AppxPackage -AllUsers"

:: Eliminar paquetes provisionados para evitar reinstalación
powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like '*3DBuilder*' -or $_.DisplayName -like '*ZuneMusic*' -or $_.DisplayName -like '*ZuneVideo*' -or $_.DisplayName -like '*Xbox*' -or $_.DisplayName -like '*BingNews*' -or $_.DisplayName -like '*GetHelp*' -or $_.DisplayName -like '*Getstarted*' -or $_.DisplayName -like '*Solitaire*' -or $_.DisplayName -like '*People*' -or $_.DisplayName -like '*Skype*' -or $_.DisplayName -like '*OfficeHub*' -or $_.DisplayName -like '*Todos*' -or $_.DisplayName -like '*Alarms*' -or $_.DisplayName -like '*FeedbackHub*' -or $_.DisplayName -like '*Maps*' -or $_.DisplayName -like '*SoundRecorder*' -or $_.DisplayName -like '*YourPhone*' -or $_.DisplayName -like '*StickyNotes*' -or $_.DisplayName -like '*OneConnect*' -or $_.DisplayName -like '*Wallet*' -or $_.DisplayName -like '*GamingApp*' -or $_.DisplayName -like '*Terminal*' -or $_.DisplayName -like '*PowerAutomate*' -or $_.DisplayName -like '*Outlook*'} | Remove-AppxProvisionedPackage -Online"

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
echo Bloqueando telemetría y recopilacion de datos...
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
timeout /t 2 >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
echo Desactivando servicios de telemetría...
sc stop WdiServiceHost >nul 2>&1
sc config WdiServiceHost start= disabled >nul 2>&1
sc stop PcaSvc >nul 2>&1
sc config PcaSvc start= disabled >nul 2>&1
sc stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul 2>&1

echo Desactivando recolección adicional de datos de diagnóstico...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo Deshabilitando permisos de aplicaciones innecesarias...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\camera" /v "Value" /t REG_SZ /d "Deny" /f
timeout /t 2 >nul

echo Deshabilitando sincronización de aplicaciones y notificaciones...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d 1 /f >nul 2>&1
timeout /t 2 /nobreak >nul

echo Desactivando notificaciones, sugerencias y anuncios...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
echo Desactivando notificaciones, sugerencias y anuncios...
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

echo Deshabilitando servicios innecesarios...
DISM /Online /Disable-Feature /FeatureName:FaxServicesClientPackage /NoRestart
sc config RemoteRegistry start= disabled
sc config Fax start= disabled
taskkill /f /im OneDrive.exe
taskkill /f /im OneDriveSetup.exe >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSync" /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowOneDrive" /t REG_DWORD /d 0 /f >nul 2>&1
timeout /t 2 >nul

echo Deshabilitando Storage Sense...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "DisableStorageSense" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 0 /f
timeout /t 2 >nul

echo Deshabilitando tareas programadas innecesarias...
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable
echo Tareas deshabilitadas correctamente.
timeout /t 2 >nul

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
echo Detectando tipo de disco...
echo.
:: Intentar detectar tipo de disco usando PowerShell (método principal)
set "disk_type="
set "disk_model="
set "disk_category=unknown"

:: Método 1: PowerShell (más confiable en Windows 11)
for /f "tokens=2 delims=:" %%a in ('powershell -command "Get-PhysicalDisk | Select-Object -First 1 MediaType | Format-List" 2^>nul ^| findstr /i "MediaType"') do (
    set "disk_type=%%a"
    set "disk_type=!disk_type: =!"
)
:: Método 2: Si PowerShell falla, usar WMIC
if "!disk_type!"=="" (
    for /f "skip=2 tokens=2,3 delims=," %%a in ('wmic diskdrive get model^,mediatype /format:csv 2^>nul') do (
        set "disk_model=%%a"
        set "disk_type=%%b"
        set "disk_type=!disk_type: =!"
        if defined disk_type goto :detected
    )
)

:detected

:: Limpiar y estandarizar el tipo de disco
if defined disk_type (
    set "disk_type=!disk_type: =!"
    echo Tipo detectado por sistema: !disk_type!
)

:: Determinar tipo de disco basado en el resultado
if /i "!disk_type!"=="SSD" (
    set "disk_category=SSD"
) else if /i "!disk_type!"=="HDD" (
    set "disk_category=HDD"
) else if defined disk_model (
    :: Revisar modelo para determinar tipo si no se detectó claramente
    echo !disk_model! | findstr /i /c:"SSD" /c:"NVMe" /c:"Samsung SSD" /c:"Crucial SSD" /c:"WD SSD" /c:"M.2" /c:"PCIe" > nul && (
        set "disk_category=SSD"
    ) || (
        echo !disk_model! | findstr /i /c:"HDD" /c:"Hard" /c:"ST" /c:"WD Blue" /c:"WD Black" /c:"Toshiba" /c:"Seagate" /c:"HGST" /c:"BarraCuda" > nul && (
            set "disk_category=HDD"
        )
    )
)

if "!disk_category!"=="unknown" (
    echo No se pudo determinar el tipo exacto del disco
    set "disk_category=unknown"
)

echo.
echo Tipo de disco detectado: !disk_category!
echo.

:: Ejecutar el comando chkdsk apropiado
if /i "!disk_category!"=="SSD" (
    echo ================================================
    echo  DISCO SSD DETECTADO
    echo  Ejecutando: chkdsk C: /F /X (optimizado para SSD)
    echo ================================================
    echo.
    echo S | chkdsk C: /F /X < nul
) else if /i "!disk_category!"=="HDD" (
    echo ================================================
    echo  DISCO DURO (HDD) DETECTADO
    echo  Ejecutando: chkdsk C: /F /R /X (con escaneo de sectores)
    echo ================================================
    echo.
    echo S | chkdsk C: /F /R /X < nul
) else (
    echo ================================================
    echo  TIPO DE DISCO DESCONOCIDO
    echo  Ejecutando: chkdsk C: /F /X (modo estándar)
    echo ================================================
    echo.
    echo S | chkdsk C: /F /X < nul
)

echo.

echo =============================================
echo 20. Optimizacion de equipos dependiendo RAM
echo =============================================

setlocal enabledelayedexpansion

:: =====================================================================
:: BLOQUE 1: Para equipos con MENOS de 8 GB de RAM
:: =====================================================================

echo Verificando RAM para optimizacion extrema...
REM Obtener la cantidad de RAM en MB
for /f %%A in ('powershell -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)" 2^>^&1') do set RAM_MB=%%A

REM Verificar si la obtención de RAM fue exitosa
if "%RAM_MB%"=="" (
    echo ERROR: No se pudo determinar la cantidad de RAM del sistema.
    echo Continuando con la siguiente verificacion.
    goto CHECK_MAS_8GB
)

REM Convertir RAM a número y comparar
set /a RAM_NUM=%RAM_MB% 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Valor de RAM invalido.
    echo Continuando con la siguiente verificacion.
    goto CHECK_MAS_8GB
)

REM Verificar si la RAM es mayor o igual a 8GB (8192 MB)
if %RAM_NUM% geq 8192 (
    echo.
    echo [SKIP] RAM >= 8GB detectada. Saltando optimización extrema (< 8GB).
    echo.
    goto CHECK_MAS_8GB
)

:: *************************************************************
:: OPTIMIZACION PARA RAM < 8GB (Solo se ejecuta si RAM < 8192 MB)
:: *************************************************************
echo ======================================================
echo SISTEMA CON %RAM_NUM% MB DE RAM (< 8GB)
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
goto END_RAM_CHECK

:: =====================================================================
:: BLOQUE 2: Para equipos con MAS de 8 GB de RAM
:: =====================================================================
:CHECK_MAS_8GB
echo Para equipos con MAS de 8 GB de RAM
echo Verificando cantidad de memoria RAM...
for /f "tokens=2 delims==" %%a in ('wmic ComputerSystem get TotalPhysicalMemory /value ^| find "="') do set TotalRAM=%%a
set /a TotalRAMGB=%TotalRAM% / 1073741824

echo Cantidad total de RAM detectada: %TotalRAMGB% GB

if %TotalRAMGB% leq 8 (
    echo.
    echo [SKIP] RAM <= 8GB. Saltando optimizaciones de bajo latencia para 8GB+.
    echo.
    goto END_RAM_CHECK
)

:: *************************************************************
:: OPTIMIZACION PARA RAM > 8GB (Solo se ejecuta si RAM > 8GB)
:: *************************************************************
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

:: =====================================================================
:: FIN DE LA LÓGICA CONDICIONAL DE RAM
:: =====================================================================
:END_RAM_CHECK
endlocal

echo ==============================================================
echo 21. GESTIÓN DE NAVEGADORES
echo ============================================================== 

:: Verificar si Brave ya está instalado
echo Comprobando si Brave Browser ya está instalado...
winget list Brave.Brave --accept-source-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo Brave Browser ya está instalado. No se realizarán cambios.
    exit /b 0
)

echo Brave Browser NO está instalado. Procediendo con la instalacion...
:: Instalar Brave Browser
winget install Brave.Brave --silent --accept-package-agreements --accept-source-agreements
if %errorlevel% neq 0 (
    echo [ERROR] Falló la instalación de Brave Browser.
    exit /b 1
)

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
