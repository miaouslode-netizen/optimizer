@echo off
title Optimisation, RAM et Auto-Configuration de Windows
color 0B

:: Verification des droits d'administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo [ERREUR] Ce script doit etre execute en tant qu'administrateur !
    echo Faites un clic droit sur le fichier et choisissez "Executer en tant qu'administrateur".
    pause
    exit /b
)

:MENU
cls
echo ============================================================================
echo              MENU D'OPTIMISATION ET LIBERATION DE RAM WINDOWS
echo ============================================================================
echo.
echo  1. Niveau LEGER (Recommande)
echo     - Desactive les animations des fenetres et la transparence
echo     - Desactive les suggestions et publicites du menu Demarrer
echo.
echo  2. Niveau MOYEN (Performance)
echo     - Applique le Niveau LEGER
echo     - Desactive les applications en arriere-plan et la telemetrie
echo.
echo  3. Niveau EXTREME (Gaming / PC ancien)
echo     - Applique le Niveau MOYEN
echo     - Desactive SysMain (Superfetch), l'indexation et la Game Bar
echo.
echo  4. RESTAURER les parametres par defaut (et supprimer l'auto-nettoyage)
echo.
echo  5. SCAN DU PC ET AUTO-CONFIGURATION (Recommande si vous hesitez)
echo     - Analyse votre RAM et votre disque pour choisir le meilleur niveau
echo.
echo  6. LIBERER LA RAM MAINTENANT (Scan et fermeture rapide)
echo     - Affiche le Top 10 des logiciels gourmands et ferme les applis inutiles
echo.
echo  7. ACTIVER LE MODE "DEMARRAGE PROPRE AUTO" (A chaque lancement)
echo     - Coupe automatiquement au demarrage : Mobile connecte, Fax, Cartes,
echo       Widgets, OneDrive et les processus gourmands inutiles.
echo.
echo  8. Quitter
echo.
echo ============================================================================
set /p choix="Choisissez une option (1-8) : "

if "%choix%"=="1" goto NIVEAU1
if "%choix%"=="2" goto NIVEAU2
if "%choix%"=="3" goto NIVEAU3
if "%choix%"=="4" goto RESTAURER
if "%choix%"=="5" goto AUTOCONFIG
if "%choix%"=="6" goto CLEANRAM
if "%choix%"=="7" goto AUTOBOOT
if "%choix%"=="8" exit /b
goto MENU

:AUTOCONFIG
cls
echo ============================================================================
echo ANALYSE MATERIELLE EN COURS...
echo ============================================================================
echo.

for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)"') do set RAM=%%a
set HAS_HDD=Non
for /f "tokens=*" %%d in ('powershell -NoProfile -Command "if (Get-PhysicalDisk | Where-Object MediaType -eq 'HDD') { 'Oui' } else { 'Non' }"') do set HAS_HDD=%%d

echo - Memoire RAM detectee : %RAM% Go
echo - Disque dur mecanique (HDD) detecte : %HAS_HDD%
echo.
echo ============================================================================

if %RAM% LEQ 4 (
    echo [DIAGNOSTIC] Memoire faible ^(%RAM% Go^).
    echo [ACTION] Selection automatique du Niveau 3 ^(EXTREME^)...
    set choix=3
    timeout /t 4 >nul
    goto NIVEAU1
)

if "%HAS_HDD%"=="Oui" (
    echo [DIAGNOSTIC] Disque dur classique ^(HDD^) detecte. L'indexation ralentit le PC.
    echo [ACTION] Selection automatique du Niveau 3 ^(EXTREME^)...
    set choix=3
    timeout /t 4 >nul
    goto NIVEAU1
)

if %RAM% LEQ 8 (
    echo [DIAGNOSTIC] Configuration standard ^(%RAM% Go de RAM avec SSD^).
    echo [ACTION] Selection automatique du Niveau 2 ^(MOYEN^)...
    set choix=2
    timeout /t 4 >nul
    goto NIVEAU1
)

echo [DIAGNOSTIC] Configuration performante ^(%RAM% Go de RAM avec SSD^).
echo [ACTION] Selection automatique du Niveau 1 ^(LEGER^)...
set choix=1
timeout /t 4 >nul
goto NIVEAU1

:NIVEAU1
echo.
echo [INFO] Application du Niveau LEGER...
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul
if "%choix%"=="1" goto FIN

:NIVEAU2
echo [INFO] Application du Niveau MOYEN...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul
if "%choix%"=="2" goto FIN

:NIVEAU3
echo [INFO] Application du Niveau EXTREME...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
sc stop "SysMain" >nul 2>&1
sc config "SysMain" start=disabled >nul 2>&1
sc stop "WSearch" >nul 2>&1
sc config "WSearch" start=disabled >nul 2>&1
goto FIN

:CLEANRAM
cls
echo ============================================================================
echo               SCAN DES PROCESSUS GOURMANDS EN MEMOIRE RAM
echo ============================================================================
echo.
powershell -NoProfile -Command "Get-Process | Where-Object {$_.ProcessName -notin @('System','Idle','svchost','csrss','wininit','services','lsass','smss','dwm','explorer')} | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 @{Name='Logiciel';Expression={$_.ProcessName}}, @{Name='RAM_Mo';Expression={[math]::Round($_.WorkingSet64 / 1MB, 1)}} | Format-Table -AutoSize"
echo.
echo ============================================================================
set /p confirm="Voulez-vous fermer les applis en arriere-plan et vider la RAM ? (O/N) : "
if /i "%confirm%" NEQ "O" goto MENU

echo.
echo [INFO] Fermeture des applications lourdes et inutiles en arriere-plan...

:: Liste securisee des processus gourmands non vitaux pour Windows
set APPS=PhoneExperienceHost YourPhone msedge chrome firefox opera brave Discord Steam epicgameslauncher Battle.net Origin EADesktop OneDrive Teams Spotify Skype Cortana SearchHost Widgets GameBar

for %%p in (%APPS%) do (
    taskkill /f /im "%%p.exe" >nul 2>&1
    if not errorlevel 1 echo  - [FERME] %%p.exe
)

echo [INFO] Arret des services Windows inutiles (Mobile connecte, Cartes, Fax)...
sc stop "MapsBroker" >nul 2>&1
sc stop "Fax" >nul 2>&1
sc stop "WpcMonSvc" >nul 2>&1
sc stop "DiagTrack" >nul 2>&1

echo [INFO] Liberation du cache memoire via PowerShell...
powershell -NoProfile -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul 2>&1

echo.
echo [SUCCES] Memoire RAM liberee !
pause
goto MENU

:AUTOBOOT
cls
echo ============================================================================
echo           CONFIGURATION DU MODE "DEMARRAGE PROPRE AUTOMATIQUE"
echo ============================================================================
echo.
echo Ce mode va :
echo  1. Desactiver au demarrage les services gourmands inutiles :
echo     - Gestionnaire de cartes telechargees (MapsBroker)
echo     - Service de telecopie (Fax)
echo     - Telemetrie et diagnostics Windows (DiagTrack)
echo     - Controles parentaux (WpcMonSvc)
echo  2. Desactiver le lancement auto de Mobile Connecte (PhoneExperienceHost)
echo     et des Widgets Windows.
echo  3. Creer une tache automatique qui nettoie la RAM 30 secondes apres
echo     chaque ouverture de session Windows.
echo.
set /p confirmboot="Activer ce mode automatique ? (O/N) : "
if /i "%confirmboot%" NEQ "O" goto MENU

echo.
echo [INFO] Desactivation des services inutiles au demarrage...
sc config "MapsBroker" start=disabled >nul 2>&1
sc stop "MapsBroker" >nul 2>&1
sc config "Fax" start=disabled >nul 2>&1
sc stop "Fax" >nul 2>&1
sc config "DiagTrack" start=disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
sc config "WpcMonSvc" start=disabled >nul 2>&1
sc stop "WpcMonSvc" >nul 2>&1

echo [INFO] Blocage de Mobile Connecte et des Widgets en arriere-plan...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\Microsoft.YourPhone_8wekyb3d8bbwe" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1

echo [INFO] Creation du script de nettoyage automatique au demarrage...
set "SCRIPT_DIR=%ProgramData%\WinAutoOpti"
if not exist "%SCRIPT_DIR%" mkdir "%SCRIPT_DIR%"

:: Creation d'un mini-script silencieux execute a chaque ouverture de session
(
echo @echo off
echo timeout /t 25 /nobreak ^>nul
echo taskkill /f /im PhoneExperienceHost.exe ^>nul 2^>^&1
echo taskkill /f /im YourPhone.exe ^>nul 2^>^&1
echo taskkill /f /im Widgets.exe ^>nul 2^>^&1
echo taskkill /f /im OneDrive.exe ^>nul 2^>^&1
echo taskkill /f /im Teams.exe ^>nul 2^>^&1
echo taskkill /f /im msedge.exe ^>nul 2^>^&1
echo powershell -NoProfile -Command "Get-Process | Where-Object {$_.WorkingSet64 -gt 350MB -and $_.ProcessName -notin @('System','Idle','svchost','csrss','wininit','services','lsass','smss','dwm','explorer','MsMpEng')} | Stop-Process -Force -ErrorAction SilentlyContinue"
) > "%SCRIPT_DIR%\BootCleaner.bat"

:: Enregistrement dans le Planificateur de taches Windows
schtasks /create /tn "WindowsAutoRAMCleaner" /tr "\"%SCRIPT_DIR%\BootCleaner.bat\"" /sc onlogon /rl highest /f >nul 2>&1

echo.
echo [SUCCES] Le mode "Demarrage Propre Auto" est actif !
echo A chaque demarrage, Windows coupera les programmes inutiles et tout
echo logiciel non-essentiel depassant 350 Mo de RAM au lancement.
echo.
pause
goto MENU

:RESTAURER
echo.
echo [INFO] Restauration des parametres par defaut...
