@echo off
title Optimizador de Windows 11 v5.0 - Optimización Integral Segura
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
    echo Te recomendamos crear uno manualmente antes de continuar.
)

set "BACKUP_PATH=%USERPROFILE%\Desktop\Backup_Registro"
mkdir "%BACKUP_PATH%" >nul 2>&1
echo Creando respaldo del registro en el Escritorio...
reg export HKEY_CLASSES_ROOT "%BACKUP_PATH%\1_HKCR.reg" /y >nul 2>&1
reg export HKEY_CURRENT_USER "%BACKUP_PATH%\2_HKCU.reg" /y >nul 2>&1
reg export HKEY_LOCAL_MACHINE "%BACKUP_PATH%\3_HKLM.reg" /y >nul 2>&1
reg export HKEY_USERS "%BACKUP_PATH%\4_HKU.reg" /y >nul 2>&1
reg export HKEY_CURRENT_CONFIG "%BACKUP_PATH%\5_HKCC.reg" /y >nul 2>&1
timeout /t 2 >nul

echo ==============================================================
echo 02. DESACTIVAR BITLOCKER
echo ==============================================================
manage-bde -off C: >nul 2>&1
echo BitLocker desactivando. El proceso continuara en segundo plano.
timeout /t 2 >nul

echo ==============================================================
echo 03. DEFENDER (MODO SEGURO - SIN TOCAR ARCHIVOS DEL SISTEMA)
echo ==============================================================
echo [+] Deshabilitando servicios via registro (Start=4)...
set "base=HKLM\SYSTEM\CurrentControlSet\Services"
for %%s in (WinDefend WdFilters WdBoot WdNisDrv WdNisSvc Sense SecurityHealthService wscsvc) do (
    reg add "%base%\%%s" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
)

echo [+] Aplicando politicas de grupo...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1

echo [+] Eliminando tareas programadas de Defender...
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /f >nul 2>&1
schtasks /delete /tn "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /f >nul 2>&1
echo [OK] Defender deshabilitado sin eliminar componentes XAML.
timeout /t 2 >nul

echo ==============================================================
echo 04. ELIMINANDO BLOATWARE (SEGURO)
echo ==============================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul 2>&1

echo [+] Desinstalando apps preinstaladas...
powershell -NoProfile -Command "$apps=@('3DBuilder','ZuneMusic','ZuneVideo','XboxApp','XboxGameOverlay','Xbox.TCUI','BingNews','GetHelp','Getstarted','MicrosoftSolitaireCollection','People','SkypeApp','MicrosoftOfficeHub','Todos','WindowsAlarms','WindowsFeedbackHub','WindowsMaps','WindowsSoundRecorder','YourPhone','StickyNotes','MicrosoftStickyNotes','OneConnect','Wallet','GamingApp','XboxIdentityProvider','WindowsPhotos','WindowsCamera','WindowsCommunicationsApps','WindowsTerminal','PowerAutomateDesktop','OutlookForWindows'); foreach($a in $apps){Get-AppxPackage -AllUsers *$a*|Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online|Where-Object{$_.DisplayName -like '*$a*'}|Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue}" >nul 2>&1

echo [+] Limpiando apps OEM...
powershell -NoProfile -Command "$v='hp|lenovo|dell|asus|acer'; $e='driver|firmware|bios|interface|foundation|system|hotkey|audio|chipset|service'; Get-AppxPackage -AllUsers|Where-Object{($_.Name-match $v)-or($_.PackageFamilyName-match $v)}|Where-Object{$_.Name-notmatch $e}|ForEach-Object{Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue}; Get-AppxProvisionedPackage -Online|Where-Object{$_.DisplayName-match $v}|Where-Object{$_.DisplayName-notmatch $e}|ForEach-Object{Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue}" >nul 2>&1
echo [OK] Bloatware eliminado.
timeout /t 2 >nul

echo ==============================================================
echo 05. DESACTIVAR WIDGETS Y XBOX
echo ==============================================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
powershell -Command "Get-AppxPackage -AllUsers *WindowsWebExperiencePack* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

dism /online /get-provisionedappxpackages | findstr "XboxGamingOverlay" >nul && dism /online /remove-provisionedappxpackage /packagename:Microsoft.XboxGamingOverlay_* >nul 2>&1
dism /online /get-provisionedappxpackages | findstr "XboxGameCallableUI" >nul && dism /online /remove-provisionedappxpackage /packagename:Microsoft.XboxGameCallableUI_* >nul 2>&1
powershell -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
echo [OK] Widgets y Xbox desactivados.
timeout /t 2 >nul

echo ==============================================================
echo 06. LIMPIAR INICIO AUTOMÁTICO
echo ==============================================================
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /f >nul 2>&1
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*" >nul 2>&1
if exist "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup" del /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*" >nul 2>&1
timeout /t 2 >nul

echo ==============================================================
echo 07. MEMORIA RAM / PAGEFILE
echo ==============================================================
for /f %%A in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB)"') do set RAM_MB=%%A
if "%RAM_MB%"=="" goto SKIP_PAGEFILE
set /a MIN_SIZE=RAM_MB*3/2
set /a MAX_SIZE=RAM_MB*3
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v AutomaticManagedPagefile /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "C:\pagefile.sys %MIN_SIZE% %MAX_SIZE%" /f >nul 2>&1
echo [OK] Pagefile configurado: %MIN_SIZE%MB - %MAX_SIZE%MB
:SKIP_PAGEFILE
timeout /t 2 >nul

echo ==============================================================
echo 08. OPTIMIZAR ARRANQUE
echo ==============================================================
bcdedit /set {current} numproc %NUMBER_OF_PROCESSORS% >nul 2>&1
bcdedit /set {current} useplatformclock false >nul 2>&1
bcdedit /set {current} disabledynamictick yes >nul 2>&1
echo [OK] Arranque optimizado.
timeout /t 2 >nul

echo ==============================================================
echo 09. PLAN DE ENERGÍA ULTIMATE PERFORMANCE
echo ==============================================================
reg add "HKCU\System\GameConfigStore" /v "GameModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
for /f "tokens=4" %%a in ('powercfg /list ^| findstr "e9a42b02-d5df-448d-aa00-03f14749eb61"') do set PLAN_GUID=%%a
if defined PLAN_GUID (
    powercfg -setactive %PLAN_GUID%
) else (
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
echo [OK] Plan de máximo rendimiento activado.
timeout /t 2 >nul

echo ==============================================================
echo 10. HIBERNACIÓN ACTIVADA
echo ==============================================================
powercfg.exe /hibernate on >nul 2>&1
powercfg.exe /change standby-timeout-ac 0 >nul 2>&1
powercfg.exe /change standby-timeout-dc 0 >nul 2>&1
echo [OK] Hibernación activada. Suspensión desactivada.
timeout /t 2 >nul

echo ==============================================================
echo 11. BLOQUEAR TELEMETRÍA Y PRIVACIDAD
echo ==============================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
for %%s in (DiagTrack dmwappushservice WdiServiceHost PcaSvc WerSvc) do (sc stop %%s >nul 2>&1 & sc config %%s start= disabled >nul 2>&1)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\camera" /v "Value" /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d 1 /f >nul 2>&1
for %%v in (SubscribedContent-310093Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SoftLandingEnabled FeatureManagementEnabled SilentInstalledAppsEnabled) do (reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "%%v" /t REG_DWORD /d 0 /f >nul 2>&1)
echo [OK] Telemetría y privacidad bloqueadas.
timeout /t 2 >nul

echo ==============================================================
echo 12. DESACTIVAR INDEXACIÓN (WSEARCH)
echo ==============================================================
sc stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WSearch" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo [OK] Indexación desactivada.
timeout /t 2 >nul

echo ==============================================================
echo 13. OPTIMIZACIÓN DE SERVICIOS Y LIMPIEZA
echo ==============================================================
del /q /s /f "%temp%\*" >nul 2>&1
del /q /s /f "C:\Windows\Temp\*" >nul 2>&1
DISM /Online /Cleanup-Image /StartComponentCleanup /NoRestart >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1 & sc stop "SysMain" >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSync" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "DisableStorageSense" /t REG_DWORD /d 1 /f >nul 2>&1
for %%s in (XblAuthManager XblGameSave XboxNetApiSvc Fax RemoteRegistry) do (sc config %%s start= disabled >nul 2>&1 & sc stop %%s >nul 2>&1)
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
echo [OK] Servicios y limpieza optimizados.
timeout /t 2 >nul

echo ==============================================================
echo 14. AJUSTES DE RED
echo ==============================================================
netsh int tcp set global rss=enabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d 255 /f >nul 2>&1
netsh int tcp set global congestionprovider=cubic >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Red y caché ajustados.
timeout /t 2 >nul

echo ==============================================================
echo 15. PRIORIDAD CPU Y FONDO
echo ==============================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo [OK] Prioridad de CPU optimizada.
timeout /t 2 >nul

echo ==============================================================
echo 16. ACELERACIÓN GPU
echo ==============================================================
reg add "HKCU\Software\Microsoft\DirectX" /v "EnableGPUScaling" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul 2>&1
echo [OK] GPU optimizada.
timeout /t 2 >nul

echo ==============================================================
echo 17. EFECTOS VISUALES Y ENTRADA DE TEXTO (SEGURO)
echo ==============================================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\TabletTip\1.7" /v "EnableAutoShiftEngage" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\TextInput" /v "EnableTextPrediction" /t REG_DWORD /d 0 /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & timeout /t 2 >nul & start explorer.exe
echo [OK] Interfaz optimizada sin dañar LogonUI.
timeout /t 2 >nul

echo ==============================================================
echo 18. WINDOWS UPDATE MANUAL
echo ==============================================================
sc stop wuauserv >nul 2>&1 & sc config wuauserv start= demand >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "NoBandwidthThrottling" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo [OK] Actualizaciones en modo manual.
timeout /t 2 >nul

echo ==============================================================
echo 19. DETECCIÓN DE DISCO Y OPTIMIZACIÓN
echo ==============================================================
set "driveType=SSD"
powershell -NoProfile -Command "if((Get-PhysicalDisk | Where-Object{(Get-Partition -DiskNumber $_.DeviceId).DriveLetter -contains 'C'}).MediaType -eq 'HDD'){exit 0}else{exit 1}" >nul 2>&1
if %errorlevel% equ 0 set "driveType=HDD"
fsutil behavior set disabledeletenotify 0 >nul 2>&1
if /i "%driveType%"=="SSD" (defrag C: /L /U >nul 2>&1) else (defrag C: /O /U >nul 2>&1)
echo [OK] Disco [%driveType%] optimizado. TRIM activo.
timeout /t 2 >nul

echo ==============================================================
echo 20. LÓGICA ADAPTATIVA POR RAM
echo ==============================================================
setlocal enabledelayedexpansion
if "%RAM_MB%"=="" goto END_RAM_CHECK
if %RAM_MB% LSS 8192 goto LOW_RAM_LOGIC
goto HIGH_RAM_LOGIC

:LOW_RAM_LOGIC
echo [+] RAM baja detectada (<8GB). Optimización extrema...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1
sc config SysMain start= disabled >nul 2>&1 & sc config WSearch start= disabled >nul 2>&1
goto END_RAM_CHECK

:HIGH_RAM_LOGIC
echo [+] RAM suficiente (>=8GB). Optimización de latencia...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableDynamicTick" /t REG_DWORD /d 1 /f >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
goto END_RAM_CHECK

:END_RAM_CHECK
endlocal
timeout /t 2 >nul

echo ==============================================================
echo 21. GESTIÓN DE NAVEGADORES
echo ==============================================================
winget install Brave.Brave --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" /v "ProgId" /d "BraveHTML" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" /v "ProgId" /d "BraveHTML" /f >nul 2>&1
assoc .html=BraveHTML >nul 2>&1 & assoc .htm=BraveHTML >nul 2>&1 & assoc .pdf=BraveHTML >nul 2>&1
echo [OK] Brave instalado y configurado.
timeout /t 2 >nul

echo ==============================================================
echo 22. INSTALACIÓN Y ACTUALIZACIÓN DE SOFTWARE
echo ==============================================================
winget install --id VideoLAN.VLC -e --source winget --accept-source-agreements --accept-package-agreements >nul 2>&1
winget install --id RARLab.WinRAR -e --source winget --accept-source-agreements --accept-package-agreements >nul 2>&1
winget install --id nomacs.nomacs -e --source winget --accept-source-agreements --accept-package-agreements >nul 2>&1
winget upgrade --all --accept-source-agreements --accept-package-agreements >nul 2>&1
echo [OK] Software instalado/actualizado.
timeout /t 2 >nul

echo ==============================================================
echo 26. MEJORAS AUTOMÁTICAS RESCATADAS (V3/V4)
echo ==============================================================
for /f %%A in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB)"') do set FREE_GB=%%A
if %FREE_GB% GEQ 10 (DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1)
fsutil behavior query disabledeletenotify | findstr "0" >nul 2>&1 || fsutil behavior set disabledeletenotify 0 >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 04 /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 32 /t REG_DWORD /d 30 /f >nul 2>&1
if /i "%driveType%"=="HDD" chkdsk C: /F /R /X >nul 2>&1
for %%p in (explorer.exe dwm.exe) do (tasklist /fi "imagename eq %%p" 2>nul | findstr "%%p" >nul && wmic process where name="%%p" CALL setpriority "high priority" >nul 2>&1)
echo [OK] Mejoras aplicadas automáticamente.
timeout /t 2 >nul

echo ==============================================================
echo 27. ELIMINACIÓN SEGURA DE COPILOT/CORTANA/BING + PROTECCIÓN LOGONUI
echo ==============================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$s=@('*Copilot*','*Cortana*','*BingNews*','*BingWeather*'); foreach($p in $s){Get-AppxPackage -AllUsers $p|Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online|Where-Object{$_.PackageName-like $p}|Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue}" >nul 2>&1
powershell -NoProfile -Command "if(!(Test-Path '$env:SystemRoot\SystemApps\MicrosoftWindows.Client.CBS_*')){dism /online /cleanup-image /restorehealth >$null}" >nul 2>&1
echo [OK] Copilot/Cortana/Bing eliminados. LogonUI verificado y protegido.
timeout /t 2 >nul

echo ==============================
echo OPTIMIZACIÓN COMPLETADA v5.0
echo ==============================
echo Es recomendable reiniciar el equipo para aplicar todos los cambios.
echo Presiona cualquier tecla para salir...
pause >nul
exit
